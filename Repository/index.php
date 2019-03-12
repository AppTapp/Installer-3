<?php

define('PACKAGES_PATH', "./packages");
define('PACKAGES_PATH_URL', "http://repository.ripdev.com/r4/packages/");	// must have the trailing '/'

define('INFO_PATH', "./info");
define('INFO_PATH_URL', "http://repository.ripdev.com/r4/info/");		// must have the trailing '/'

// No user serviceable parts beyond this point.

ob_start("ob_gzhandler");

$installer_version = @$_REQUEST['installerVersion'];
$os_version = @$_REQUEST['firmwareVersion'];
$platform = @$_REQUEST['platform'];
$deviceUUID = @$_REQUEST['deviceUUID'];

if(!$_GET['debug'] && !(strstr($_SERVER['HTTP_USER_AGENT'], 'AppTapp Installer') || strstr($_SERVER['HTTP_USER_AGENT'], 'CFNetwork')))
{
	include("../instructions.php");
}
else
{
	if ($_GET['debug'])
		header('Content-Type: text/plain; charset=utf-8');
	else
		header('Content-Type: application/x-apptapp-repository; charset=utf-8');

	$index = new DOMDocument();
	$index->load('Info.plist');
	$repoInfo = $index->getElementsByTagName('dict')->item(0);
	
	$repoInfo->appendChild($index->createElement('key', 'packages'));
	$packages = $index->createElement('array');
	$repoInfo->appendChild($packages);

	gather_categories();
	
	print $index->saveXML();
}

exit;

function gather_categories()
{
	$dir = opendir(PACKAGES_PATH);
	if ($dir)
	{
		while ($path = readdir($dir))
		{
			if ($path == '.' or $path == '..')
				continue;
			
			// traverse category
			scan_category(PACKAGES_PATH . "/" . $path, $path);
		}
	}
	
	closedir($dir);
}

function scan_category($path, $category)
{
	global $packages, $index;
	
	$dir = opendir($path);
	if (!$dir)
		return;
	
	while ($file = readdir($dir))
	{
		$fullpath = $path.'/'.$file;
		
		if (pathinfo($fullpath, PATHINFO_EXTENSION) == 'zip')
		{
			$pkgInfo = trim(get_from_zip($fullpath, 'AppTapp.plist'));
			
			if ($pkgInfo and strlen($pkgInfo))
			{
				$package = new DOMDocument;
				$package->loadXML($pkgInfo);
				
				$r = parsePlist($package);
				
				$dict = $package->createElement('dict');
				
				// Category
				$dict->appendChild($package->createElement('key', 'category'));
				$dict->appendChild($package->createElement('string', htmlentities($category, ENT_QUOTES, 'UTF-8')));
				
				// Package date
				$dict->appendChild($package->createElement('key', 'date'));
				$dict->appendChild($package->createElement('string', filemtime($fullpath)));
				
				// Package ID
				$dict->appendChild($package->createElement('key', 'identifier'));
				$dict->appendChild($package->createElement('string', htmlentities($r['identifier'], ENT_QUOTES, 'UTF-8')));
				
				// Package Name
				$dict->appendChild($package->createElement('key', 'name'));
				$dict->appendChild($package->createElement('string', htmlentities($r['name'], ENT_QUOTES, 'UTF-8')));

				// Package Version
				$dict->appendChild($package->createElement('key', 'version'));
				$dict->appendChild($package->createElement('string', htmlentities($r['version'], ENT_QUOTES, 'UTF-8')));
				
				// Package Description
				$dict->appendChild($package->createElement('key', 'description'));
				$dict->appendChild($package->createElement('string', htmlentities($r['description'], ENT_QUOTES, 'UTF-8')));

				// Package icon
				if ($r['icon'])
				{
					$dict->appendChild($package->createElement('key', 'icon'));
					$dict->appendChild($package->createElement('string', htmlentities($r['icon'], ENT_QUOTES, 'UTF-8')));					
				}

				// And finally, more info location :)
				$dict->appendChild($package->createElement('key', 'url'));
				$dict->appendChild($package->createElement('string', htmlentities(INFO_PATH_URL . $r['identifier'] . '.plist', ENT_QUOTES, 'UTF-8')));
				
				$child = $index->importNode($dict, true);
				$packages->appendChild($child);
				
				// And since we're at it, create the more info plist for the package
				$r['size'] = filesize($fullpath);
				$r['hash'] = md5_file($fullpath);
				$r['location'] = PACKAGES_PATH_URL . $category . "/" . $file;
				unset($r['scripts']);
				
				// Spool it into the more info file
				$FILE = fopen(INFO_PATH . '/' . $r['identifier'] . '.plist', "w");
				if ($FILE)
				{
					fwrite($FILE, _plist_output($r));
					fclose($FILE);
				}
			}
		}
	}
}

function get_from_zip($zip_path, $filename)
{
	$result = shell_exec('unzip -pC ' . escapeshellarg($zip_path) . ' ' . escapeshellarg($filename));
	
	return $result;
}

// parsing

function parsePlist( $document ) {
  $plistNode = $document->documentElement;

  $root = $plistNode->firstChild;

  // skip any text nodes before the first value node
  while ( $root->nodeName == "#text" ) {
    $root = $root->nextSibling;
  }

  return parseValue($root);
}

function parseValue( $valueNode ) {
  $valueType = $valueNode->nodeName;

  $transformerName = "parse_$valueType";

  if ( is_callable($transformerName) ) {
    // there is a transformer function for this node type
    return call_user_func($transformerName, $valueNode);
  }

  // if no transformer was found
  return null;
}

function parse_integer( $integerNode ) {
	return $integerNode->textContent;
}

function parse_string( $stringNode ) {
	return $stringNode->textContent;
}

function parse_date( $dateNode ) {
	return $dateNode->textContent;
}

function parse_true( $trueNode ) {
	return true;
}

function parse_false( $trueNode ) {
	return false;
}

function parse_dict( $dictNode ) {
  $dict = array();

  // for each child of this node
  for (
    $node = $dictNode->firstChild;
    $node != null;
    $node = $node->nextSibling
  ) {
    if ( $node->nodeName == "key" ) {
      $key = $node->textContent;

      $valueNode = $node->nextSibling;

      // skip text nodes
      while ( $valueNode->nodeType == XML_TEXT_NODE ) {
        $valueNode = $valueNode->nextSibling;
      }

      // recursively parse the children
      $value = parseValue($valueNode);

      $dict[$key] = $value;
    }
  }

  return $dict;
}

function parse_array( $arrayNode ) {
  $array = array();

  for (
    $node = $arrayNode->firstChild;
    $node != null;
    $node = $node->nextSibling
  ) {
    if ( $node->nodeType == XML_ELEMENT_NODE ) {
      array_push($array, parseValue($node));
    }
  }

  return $array;
}

// Converting back

function _plist_output($plist, $full = true, $in_array = false)
{
	$c = '';
	
	foreach ($plist as $key => $value)
	{
		if (!$in_array)
			$c .= "<key>".htmlentities($key, ENT_NOQUOTES, 'utf-8')."</key>\n";
		if (is_bool($value))
		{
			if ($value)
				$c .= "<true/>\n";
			else
				$c .= "<false/>\n";
		}
		else if (is_int($value))
		{
			$c .= "<integer>$value</integer>\n";
		}
		else if (is_float($value))
		{
			$c .= "<float>$value</float>\n";
		}
		else if (is_array($value))
		{
			// we got two types of arrays, numeric ones, and keyed ones, which we interpret as dictionary.
			// lets figure out which one is it
			$has_symbolic_keys = false;
			
			foreach (array_keys($value) as $key)
			{
				if (!is_numeric($key))
					$has_symbolic_keys = true;
			}
			
			if ($has_symbolic_keys)
				$c .= "<dict>\n";
			else
				$c .= "<array>\n";
			
			$c .= _plist_output($value, false, !$has_symbolic_keys);
			
			if ($has_symbolic_keys)
				$c .= "</dict>\n";
			else
				$c .= "</array>\n";
		}
		else if (is_object($value) and is_a($value, "BLOB"))
		{
			$c .= "<data>\n";
			$c .= base64_encode($value->data);
			$c .= "\n</data>\n";
		}
		else
			$c .= "<string>" . htmlentities($value, ENT_NOQUOTES, 'utf-8')."</string>\n";
	}
	
	if ($full)
	{
		header("Content-Type: text/xml; encoding=utf-8");
		
		$final = '<?xml version="1.0" encoding="UTF-8"?>';
		$final .= "\n";
		$final .= '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">';
		$final .= "\n";
		$final .= '<plist version="1.0">';
		$final .= "\n";
		$final .= "<dict>\n";
		$final .= $c;
		$final .= "</dict>\n</plist>\n";
		return $final;
	}
	else
		return $c;
}

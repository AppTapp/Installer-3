//AppTapp Installer Writer by lex
#include <libxml/parser.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlwriter.h>
#include <string.h>
#include <stdio.h>

xmlTextWriterPtr writer;
char bundleIdentifier[1024];
char name[1024];
char version[1024];
char size[1024];
char location[1024];
char url[1024];
char time[1024];
char category[1024];
char description[1024];
char copypathinstallfilepath[1024];
char copypathsourcefilepath[1024];
char removepathinstalledfilepath[1024];
char execinstalledfilepath[1024];
char execarg[1024];
char md5[1024];

void copypath(){
	char copypathanswer;
	printf("\nWould you like to add a CopyPath? Enter (y/n): \n");
	scanf(" %c", &copypathanswer);
	printf("\n answer is %c\n", copypathanswer);
	while (copypathanswer == 'y'){
		
    xmlTextWriterStartElement(writer,(xmlChar *)"array");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)"CopyPath");
		
    printf("Enter file or directory in package:\n");
    scanf(" %1024[^\n]", copypathsourcefilepath);
		
    printf("Enter install path of previous file or directory in package:\n");
    scanf(" %1024[^\n]", copypathinstallfilepath);
        
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)copypathsourcefilepath);
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)copypathinstallfilepath);
    
    xmlTextWriterEndElement(writer);
	printf("\nWould you like to add another CopyPath? Enter (y/n): \n");
		
    scanf(" %c", &copypathanswer);
    printf("\n answer is %c\n", copypathanswer);
		
	}
}

void removepath(){
	char removepathanswer;
	printf("\nWould you like to add a RemovePath? Enter (y/n): \n");
	scanf(" %c", &removepathanswer);
	printf("\n answer is %c\n", removepathanswer);
	while (removepathanswer == 'y'){

    xmlTextWriterStartElement(writer,(xmlChar *)"array");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)"RemovePath");
		
    printf("Enter install path of previous file or directory in package:\n");
    scanf(" %1024[^\n]", removepathinstalledfilepath);
		
	char removeanotherpathanswer;
    printf("\nWould you like to remove another path with RemovePath? Enter (y/n): \n");
    scanf(" %c", &removeanotherpathanswer);
    printf("\n answer is %c\n", removeanotherpathanswer);
    while (removeanotherpathanswer == 'y'){
        
    printf("Enter install path of previous file or directory in package:\n");
    scanf(" %1024[^\n]", removepathinstalledfilepath);
		
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)removepathinstalledfilepath);

    printf("\nWould you like to remove another path with RemovePath? Enter (y/n): \n");
        scanf(" %c", &removeanotherpathanswer);
        printf("\n answer is %c\n", removeanotherpathanswer);
    }
		
    xmlTextWriterEndElement(writer);
    printf("\nWould you like to add another RemovePath? Enter (y/n): \n");
		
    scanf(" %c", &removepathanswer);
    printf("\n answer is %c\n", removepathanswer);
		
	}
}

void exec(){
	char execanswer;
	printf("\nWould you like to add a Exec? Enter (y/n): \n");
	scanf(" %c", &execanswer);
	printf("\n answer is %c\n", execanswer);
	while (execanswer == 'y'){

    xmlTextWriterStartElement(writer,(xmlChar *)"array");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)"Exec");
		
    printf("Enter the binary to exec:\n");
    scanf(" %1024[^\n]", execinstalledfilepath);
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)execinstalledfilepath);
		
	char execarganswer;
    printf("\nWould you like to add another arg for this Exec? Enter (y/n): \n");
    scanf(" %c", &execarganswer);
    printf("\n answer is %c\n", execarganswer);
    while (execarganswer == 'y'){
    
    printf("Enter arg for this Exec:\n");
    scanf(" %1024[^\n]", execarg);
		
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)execarg);
    
    printf("\nWould you like to add another arg to this Exec? Enter (y/n): \n");
	scanf(" %c", &execarganswer);
        printf("\n answer is %c\n", execarganswer);
    }
    
    xmlTextWriterEndElement(writer);
    printf("\nWould you like to add another Exec? Enter (y/n): \n");
		
    scanf(" %c", &execanswer);
    printf("\n answer is %c\n", execanswer);
		
	}

}

void execnoerror(){
	char execnoerroranswer;
	printf("\nWould you like to add an ExecNoError? Enter (y/n): \n");
	scanf(" %c", &execnoerroranswer);
	printf("\n execnoerroranswer is %c\n", execnoerroranswer);
	while (execnoerroranswer == 'y'){

    xmlTextWriterStartElement(writer,(xmlChar *)"array");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)"ExecNoError");
    
    printf("Enter the binary to exec:\n");
    scanf(" %1024[^\n]", execinstalledfilepath);
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)execinstalledfilepath);
    
    char execnoerrorarganswer;
    printf("\nWould you like to add another arg for this ExecNoError? Enter (y/n): \n");
    scanf(" %c", &execnoerrorarganswer);
    printf("\n answer is %c\n", execnoerrorarganswer);
    while (execnoerrorarganswer == 'y'){
        
    printf("Enter arg for this ExecNoError:\n");
    scanf(" %1024[^\n]", execarg);
    
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)execarg);
    
    printf("\nWould you like to add another arg to this ExecNoError? Enter (y/n): \n");
        scanf(" %c", &execnoerrorarganswer);
        printf("\n answer is %c\n", execnoerrorarganswer);
    }
		
    xmlTextWriterEndElement(writer);
    printf("\nWould you like to add another ExecNoError? Enter (y/n): \n");
    
    scanf(" %c", &execnoerroranswer);
    printf("\n answer is %c\n", execnoerroranswer);
		
	}
}

int main(){
	
	printf("Enter BundleID:\n");
	scanf(" %1024[^\n]", bundleIdentifier);
	printf("Enter Name:\n");
 	scanf(" %1024[^\n]", name);
	printf("Enter Version:\n");
	scanf(" %1024[^\n]", version);
	printf("Enter Size:\n");
	scanf(" %1024[^\n]", size);
	printf("Enter Location:\n");
	scanf(" %1024[^\n]", location);
	printf("Enter URL:\n");
	scanf(" %1024[^\n]", url);
	printf("Enter Category:\n");
	scanf(" %1024[^\n]", category);
	printf("Enter Description:\n");
	scanf(" %1024[^\n]", description);
	printf("Enter Unix Time:\n");
	scanf(" %1024[^\n]", time);
	
    writer = xmlNewTextWriterFilename("i3.xml", 0);

    xmlTextWriterSetIndent(writer,1);


    xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"bundleIdentifier");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)bundleIdentifier);
	
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"name");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)name);
	
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"version");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)version);
	
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"size");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)size);
	
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"location");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)location);
    
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"url");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)url);
    
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"description");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)description);
    
	char md5answer;
    printf("\nWould you like to add an MD5 for you package file? This is optional. Enter (y/n): \n");
    scanf(" %c", &md5answer);
    printf("\n answer is %c\n", md5answer);
    if (md5answer == 'y'){
        
    printf("Enter the MD5:\n");
    scanf(" %1024[^\n]", md5);
		
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"MD5");
	xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)md5);  
    }      

    
	xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"scripts");	
    xmlTextWriterStartElement(writer,(xmlChar *)"dict");
    
	printf("\n stating element: Install\n");
    
    xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"install");		
    xmlTextWriterStartElement(writer,(xmlChar *)"array");
		
    exec();
    copypath();
    removepath();    
    execnoerror();
    
	printf("\n stating element: Uninstall\n");
	
    xmlTextWriterEndElement(writer);
	
    xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"Uninstall");
    xmlTextWriterStartElement(writer,(xmlChar *)"array");	
	
    exec();
    copypath();
    removepath();    
    execnoerror();
	
	xmlTextWriterEndElement(writer);
    xmlTextWriterEndElement(writer);

    xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"Category");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)category);
    xmlTextWriterWriteElement(writer,(xmlChar *)"key",(xmlChar *)"date");
    xmlTextWriterWriteElement(writer,(xmlChar *)"string", (xmlChar *)time);
    
    xmlTextWriterEndElement(writer);
    xmlTextWriterEndDocument(writer);
    xmlFreeTextWriter(writer);
  
    exit(0);
}


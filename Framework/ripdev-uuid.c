#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>
#include <SystemConfiguration/SystemConfiguration.h>

#define	DEVICEID_MAC		1
#define	DEVICEID_MAC_BT		2
#define	DEVICEID_MAC_BT_ex	3

static void __cleanup_device_id(char * destination, CFStringRef source)
{
	char buffer[256];
	char * p = buffer;
	char * q  = destination;

	if (CFStringGetCString(source, buffer, sizeof(buffer), kCFStringEncodingMacRoman))
		while (*p != 0)
		{
			if (isxdigit(*p))
				*q++ = tolower(*p++);
			else
				p++;
		}

	*q = 0;
}

static int __ripdev_uuid(int device_mode, unsigned int * key1, unsigned int * key2)
{
	int res = -1;
	
	char buffer[256];

	*key1 = 0;
	*key2 = 0;

	switch (device_mode)
	{
	case DEVICEID_MAC:
		{
			CFArrayRef interfaces = SCNetworkInterfaceCopyAll();
			if (interfaces != NULL)
			{
				int i, count = CFArrayGetCount(interfaces);

				for (i = 0; i < count; i++)
				{
					CFStringRef interface_type, interface_macaddress;
		            SCNetworkInterfaceRef interface = CFArrayGetValueAtIndex(interfaces, i);

					interface_type = SCNetworkInterfaceGetInterfaceType(interface);
					if (CFStringCompare(interface_type, kSCNetworkInterfaceTypeIEEE80211, 0) == 0)
					{
						interface_macaddress = SCNetworkInterfaceGetHardwareAddressString(interface);
						if (interface_macaddress != NULL)
						{
							__cleanup_device_id(buffer, interface_macaddress);
							if (strlen(buffer) == 12 && sscanf(buffer, "%4x%8x", key1, key2))
							{
							//	workaround for zibri's ego
								
								if (*key1 == 0x0000005a && *key2 == 0x49425249)
								{
									res = __ripdev_uuid(DEVICEID_MAC_BT_ex, key1, key2);
									if (res == 0)
									{
										uint64_t cummulative = ((uint64_t)*key1 << 32) | *key2;
										
										cummulative += 1;
										
										*key1 = cummulative >> 32;
										*key2 = cummulative;
										
										goto strip;
									}
								}
								else
								{
								strip:
								
									*key1 ^= (*key2 & 0x0000ffff);	//	mess MAC address a bit
									*key2 ^= 0xdeadbeef;

									res = 0;
								}
							}
						}

						break;
					}
				}
			}
		}
		break;

	case DEVICEID_MAC_BT_ex:
	case DEVICEID_MAC_BT:
		{
			CFMutableDictionaryRef matching = IOServiceNameMatching("bluetooth");
			if (matching != NULL)
			{
				io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
				if (service != 0)
				{
					CFTypeRef property = IORegistryEntrySearchCFProperty(service, kIODeviceTreePlane, CFSTR("local-mac-address"), kCFAllocatorDefault, kIORegistryIterateRecursively);
					if (property != NULL)
					{
						const uint8_t * bt = CFDataGetBytePtr(property);
						if (bt != NULL)
						{
							*key1 = (bt[0] << 8) | bt[1];
							*key2 = (bt[2] << 24) | (bt[3] << 16) | (bt[4] << 8) | bt[5];

							if (device_mode == DEVICEID_MAC_BT)
							{
								*key1 ^= (*key2 & 0x0000ffff);	//	mess MAC address a bit
								*key2 ^= 0xdeadbeef;
							}

							res = 0;
						}

						CFRelease(property);
					}

					IOObjectRelease(service);
				}
			}
		}
		break;
	
	default:
		break;
	}

	return res;
}

int ripdev_uuid(char * uuid)
{
	int result;
	unsigned int key1, key2;
	
	result = __ripdev_uuid(DEVICEID_MAC, &key1, &key2);
	if (result == 0)
		sprintf(uuid, "UID%.4X%.8X", key1, key2);

	return result;
}

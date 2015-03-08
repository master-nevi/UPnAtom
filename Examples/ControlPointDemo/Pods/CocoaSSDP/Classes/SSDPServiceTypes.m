//
//  SSDPServiceTypes.m
//  Copyright (c) 2014 Stephane Boisson
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

NSString *const SSDPServiceType_All = @"ssdp:all";

NSString *const SSDPServiceType_UPnP_RootDevice = @"upnp:rootdevice";

// UPnP Internet Gateway Device (IGD)
NSString *const SSDPServiceType_UPnP_InternetGatewayDevice1 = @"urn:schemas-upnp-org:device:InternetGatewayDevice:1";
NSString *const SSDPServiceType_UPnP_WANConnectionDevice1 = @"urn:schemas-upnp-org:device:WANConnectionDevice:1";
NSString *const SSDPServiceType_UPnP_WANDevice1 = @"urn:schemas-upnp-org:device:WANDevice:1";
NSString *const SSDPServiceType_UPnP_WANCommonInterfaceConfig1 = @"urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1";
NSString *const SSDPServiceType_UPnP_WANIPConnection1 = @"urn:schemas-upnp-org:service:WANIPConnection:1";
NSString *const SSDPServiceType_UPnP_Layer3Forwarding1 = @"urn:schemas-upnp-org:service:Layer3Forwarding:1";

// UPnP A/V profile
NSString *const SSDPServiceType_UPnP_MediaServer1 = @"urn:schemas-upnp-org:device:MediaServer:1";
NSString *const SSDPServiceType_UPnP_MediaRenderer1 = @"urn:schemas-upnp-org:device:MediaRenderer:1";
NSString *const SSDPServiceType_UPnP_ContentDirectory1 = @"urn:schemas-upnp-org:service:ContentDirectory:1";
NSString *const SSDPServiceType_UPnP_RenderingControl1 = @"urn:schemas-upnp-org:service:RenderingControl:1";
NSString *const SSDPServiceType_UPnP_ConnectionManager1 = @"urn:schemas-upnp-org:service:ConnectionManager:1";
NSString *const SSDPServiceType_UPnP_AVTransport1 = @"urn:schemas-upnp-org:service:AVTransport:1";

// UPnP Microsoft A/V profile
NSString *const SSDPServiceType_Microsoft_MediaReceiverRegistrar1 = @"urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1";

// UPnP Sonos
NSString *const SSDPServiceType_UPnP_SonosZonePlayer1 = @"urn:schemas-upnp-org:device:ZonePlayer:1";

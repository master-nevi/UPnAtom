//
//  NetworkTools.m
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "NetworkTools.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netdb.h>

@implementation NetworkTools

/* 
 Code used from: http://stackoverflow.com/questions/12690622/detect-any-connected-network
 */
+ (NSDictionary *)getIFAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionary];
    
    struct ifaddrs *interfaces = NULL;
    if (getifaddrs(&interfaces) == 0) {
        // For each interface ...
        for (struct ifaddrs *ptr = interfaces; ptr != NULL; ptr = ptr->ifa_next) {
            unsigned int flags = ptr->ifa_flags;
            struct sockaddr *addr = ptr->ifa_addr;
            NSString *interfaceName = [NSString stringWithCString:ptr->ifa_name encoding:NSUTF8StringEncoding];
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (interfaceName.length && (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) {
                if (addr->sa_family == AF_INET || addr->sa_family == AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    char host[NI_MAXHOST];
                    if (getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST) == 0) {
                        NSString *address = [NSString stringWithCString:host encoding:NSUTF8StringEncoding];
                        if (address.length) {
                            addresses[interfaceName] = address;
                        }
                    }
                }
            }
        }
    }
    freeifaddrs(interfaces);
    
    return addresses;
}

@end

/*
 * rfid.h
 *
 *  Created on: 06.20.2016
 *      Author: will dolan
 */

#ifndef CURLREQ_H_
#define CURLREQ_H_

#include <string.h>
#include <stdint.h>
#include <stdio.h>

size_t writeCallback(char* buf, size_t size, size_t nmemb, void* up);
void ReqJMN(char *resp, char *RFID, char *req, char *info, char* station);
void composeURL(char *URL, char *RFID, char *req, char *info, char *station);
void execute_curl(char *resp, char *httpURL);
void execute_photo_post(char *resp, char *httpURL, char *info);

#endif /* CURLREQ_H_ */

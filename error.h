#ifndef XLINK_ERROR_H
#define XLINK_ERROR_H

#include <stdio.h>

#include "xlink.h"
#include "util.h"

#define SET_ERROR(c, f, ...) xlink_error->code = c; sprintf(xlink_error->message, f, ##__VA_ARGS__); logger->error(f, ##__VA_ARGS__); 
#define CLEAR_ERROR_IF(r) if (r) { xlink_error->code = XLINK_SUCCESS; sprintf(xlink_error->message, "Success"); }
#define CLEAR_ERROR CLEAR_ERROR_IF(true)

#endif // XLINK_ERROR_H

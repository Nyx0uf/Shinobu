#ifndef MPD_ALBUMART_H
#define MPD_ALBUMART_H

#include "compiler.h"

struct mpd_connection;

#ifdef __cplusplus
extern "C" {
#endif

long long
mpd_run_albumart(struct mpd_connection *connection, const char *uri, unsigned char **buf);

#ifdef __cplusplus
}
#endif

#endif

#ifndef _METERPRETER_SOURCE_EXTENSION_PRIV_PRIV_H
#define _METERPRETER_SOURCE_EXTENSION_PRIV_PRIV_H

#include "../../common/common.h"

#define TLV_TYPE_EXTENSION_PRIV 0
#define TLV_EXTENSIONS                 20000

#define TLV_TYPE_SAM_HASHES            \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_STRING,      \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 1)

#define TLV_TYPE_FS_FILE_MODIFIED      \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_UINT,        \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 100)
#define TLV_TYPE_FS_FILE_ACCESSED      \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_UINT,        \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 101)
#define TLV_TYPE_FS_FILE_CREATED       \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_UINT,        \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 102)
#define TLV_TYPE_FS_FILE_EMODIFIED     \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_UINT,        \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 103)
#define TLV_TYPE_FS_FILE_PATH          \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_STRING,      \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 110)
#define TLV_TYPE_FS_SRC_FILE_PATH      \
		MAKE_CUSTOM_TLV(                 \
				TLV_META_TYPE_STRING,      \
				TLV_TYPE_EXTENSION_PRIV,   \
				TLV_EXTENSIONS + 111)

#endif

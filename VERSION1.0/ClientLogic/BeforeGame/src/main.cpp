#include "NDGameApplication.h"
#include "cocos2d.h"
#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>

#define  LOG_TAG    "main"
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)

extern "C"
{

jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
	JniHelper::setJavaVM(vm);

	return JNI_VERSION_1_4;
}

}
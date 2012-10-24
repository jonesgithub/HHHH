/****************************************************************************
Copyright (c) 2010-2011 cocos2d-x.org
Copyright (c) 2008      Apple Inc. All Rights Reserved.

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/



/*
* Support for RGBA_4_4_4_4 and RGBA_5_5_5_1 was copied from:
* https://devforums.apple.com/message/37855#37855 by a1studmuffin
*/

#include "CCTexture2D.h"

#include "ccConfig.h"
#include "ccMacros.h"
#include "CCConfiguration.h"
#include "platform/platform.h"
#include "CCImage.h"
#include "CCGL.h"
#include "support/ccUtils.h"
#include "platform/CCPlatformMacros.h"
#include "CCTexturePVR.h"
#include "CCDirector.h"

#if CC_ENABLE_CACHE_TEXTTURE_DATA
    #include "CCTextureCache.h"
#endif

#if ND_MOD
	#include "png.h"
#endif

#if ND_MOD
	#define PNG_BYTES_TO_CHECK 8
	#define png_infopp_NULL (png_infopp)NULL	
#endif


namespace   cocos2d {

#if ND_MOD
	#define alpha_composite(composite, fg, alpha, bg) {                     \
		unsigned short temp = ((unsigned short)(fg)*(unsigned short)(alpha) +                       \
		(unsigned short)(bg)*(unsigned short)(255 - (unsigned short)(alpha)) + (unsigned short)128);       \
		(composite) = (u_char)((temp + (temp >> 8)) >> 8);                   \
}
#endif

#if CC_FONT_LABEL_SUPPORT
// FontLabel support
#endif// CC_FONT_LABEL_SUPPORT

//CLASS IMPLEMENTATIONS:

// If the image has alpha, you can create RGBA8 (32-bit) or RGBA4 (16-bit) or RGB5A1 (16-bit)
// Default is: RGBA8888 (32-bit textures)
static CCTexture2DPixelFormat g_defaultAlphaPixelFormat = kCCTexture2DPixelFormat_Default;

// By default PVR images are treated as if they don't have the alpha channel premultiplied
static bool PVRHaveAlphaPremultiplied_ = false;

CCTexture2D::CCTexture2D()
: m_uPixelsWide(0)
, m_uPixelsHigh(0)
, m_uName(0)
, m_fMaxS(0.0)
, m_fMaxT(0.0)
, m_bHasPremultipliedAlpha(false)
, m_bPVRHaveAlphaPremultiplied(true)
#if ND_MOD
, m_pData(0)
, m_bKeepData(false)
, m_nContainerType(0)
, m_uiWidth(0), m_uiHeight(0)
#endif
{
}

CCTexture2D::~CCTexture2D()
{
#if CC_ENABLE_CACHE_TEXTTURE_DATA
    VolatileTexture::removeTexture(this);
#endif

	CCLOGINFO("cocos2d: deallocing CCTexture2D %u.", m_uName);
	if(m_uName)
	{
		glDeleteTextures(1, &m_uName);
	}
}

CCTexture2DPixelFormat CCTexture2D::getPixelFormat()
{
	return m_ePixelFormat;
}

unsigned int CCTexture2D::getPixelsWide()
{
	return m_uPixelsWide;
}

unsigned int CCTexture2D::getPixelsHigh()
{
	return m_uPixelsHigh;
}

GLuint CCTexture2D::getName()
{
	return m_uName;
}

const CCSize& CCTexture2D::getContentSizeInPixels()
{
	return m_tContentSize;
}

CCSize CCTexture2D::getContentSize()
{
	CCSize ret;
	ret.width = m_tContentSize.width / CC_CONTENT_SCALE_FACTOR();
	ret.height = m_tContentSize.height / CC_CONTENT_SCALE_FACTOR();

	return ret;
}

GLfloat CCTexture2D::getMaxS()
{
	return m_fMaxS;
}

void CCTexture2D::setMaxS(GLfloat maxS)
{
	m_fMaxS = maxS;
}

GLfloat CCTexture2D::getMaxT()
{
	return m_fMaxT;
}
    
ccResolutionType CCTexture2D::getResolutionType()
{
    return m_eResolutionType; 
}

void CCTexture2D::setResolutionType(ccResolutionType resolution)
{
    m_eResolutionType = resolution;
}

void CCTexture2D::setMaxT(GLfloat maxT)
{
	m_fMaxT = maxT;
}

void CCTexture2D::releaseData(void *data)
{
    free(data);
}

void* CCTexture2D::keepData(void *data, unsigned int length)
{
    CC_UNUSED_PARAM(length);
	//The texture data mustn't be saved becuase it isn't a mutable texture.
	return data;
}

bool CCTexture2D::getHasPremultipliedAlpha()
{
	return m_bHasPremultipliedAlpha;
}

bool CCTexture2D::initWithData(const void *data, CCTexture2DPixelFormat pixelFormat, unsigned int pixelsWide, unsigned int pixelsHigh, const CCSize& contentSize)
{
	glPixelStorei(GL_UNPACK_ALIGNMENT,1);
	glGenTextures(1, &m_uName);
	glBindTexture(GL_TEXTURE_2D, m_uName);

	this->setAntiAliasTexParameters();

	// Specify OpenGL texture image

	switch(pixelFormat)
	{
	case kCCTexture2DPixelFormat_RGBA8888:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
		break;
	case kCCTexture2DPixelFormat_RGB888:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
		break;
	case kCCTexture2DPixelFormat_RGBA4444:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, data);
		break;
	case kCCTexture2DPixelFormat_RGB5A1:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, data);
		break;
	case kCCTexture2DPixelFormat_RGB565:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
		break;
	case kCCTexture2DPixelFormat_AI88:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, data);
		break;
	case kCCTexture2DPixelFormat_A8:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, (GLsizei)pixelsWide, (GLsizei)pixelsHigh, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
		break;
	default:
		CCAssert(0, "NSInternalInconsistencyException");

	}

	m_tContentSize = contentSize;
	m_uPixelsWide = pixelsWide;
	m_uPixelsHigh = pixelsHigh;
	m_ePixelFormat = pixelFormat;
	m_fMaxS = contentSize.width / (float)(pixelsWide);
	m_fMaxT = contentSize.height / (float)(pixelsHigh);

	m_bHasPremultipliedAlpha = false;

	m_eResolutionType = kCCResolutionUnknown;

	return true;
}


char * CCTexture2D::description(void)
{
	char *ret = new char[100];
	sprintf(ret, "<CCTexture2D | Name = %u | Dimensions = %u x %u | Coordinates = (%.2f, %.2f)>", m_uName, m_uPixelsWide, m_uPixelsHigh, m_fMaxS, m_fMaxT);
	return ret;
}

// implementation CCTexture2D (Image)

bool CCTexture2D::initWithImage(CCImage *uiImage)
{
	return initWithImage(uiImage, kCCResolutionUnknown);
}

bool CCTexture2D::initWithImage(CCImage * uiImage, ccResolutionType resolution)
{
	unsigned int POTWide, POTHigh;

	if(uiImage == NULL)
	{
		CCLOG("cocos2d: CCTexture2D. Can't create Texture. UIImage is nil");
		this->release();
		return false;
	}

	CCConfiguration *conf = CCConfiguration::sharedConfiguration();

#if CC_TEXTURE_NPOT_SUPPORT
	if( conf->isSupportsNPOT() ) 
	{
		POTWide = uiImage->getWidth();
		POTHigh = uiImage->getHeight();
	}
	else 
#endif
	{
		POTWide = ccNextPOT(uiImage->getWidth());
		POTHigh = ccNextPOT(uiImage->getHeight());
	}

	unsigned maxTextureSize = conf->getMaxTextureSize();
	if( POTHigh > maxTextureSize || POTWide > maxTextureSize ) 
	{
		CCLOG("cocos2d: WARNING: Image (%u x %u) is bigger than the supported %u x %u", POTWide, POTHigh, maxTextureSize, maxTextureSize);
		this->release();
		return NULL;
	}

	m_eResolutionType = resolution;

	// always load premultiplied images
	return initPremultipliedATextureWithImage(uiImage, POTWide, POTHigh);
}
bool CCTexture2D::initPremultipliedATextureWithImage(CCImage *image, unsigned int POTWide, unsigned int POTHigh)
{
	unsigned char*			data = NULL;
	unsigned char*			tempData =NULL;
	unsigned int*			inPixel32 = NULL;
	unsigned short*			outPixel16 = NULL;
	bool					hasAlpha;
	CCSize					imageSize;
	CCTexture2DPixelFormat	pixelFormat;

	hasAlpha = image->hasAlpha();

	size_t bpp = image->getBitsPerComponent();

    // compute pixel format
	if(hasAlpha)
	{
		pixelFormat = g_defaultAlphaPixelFormat;
	}
	else
	{
		if (bpp >= 8)
		{
			pixelFormat = kCCTexture2DPixelFormat_RGB888;
		}
		else
		{
			CCLOG("cocos2d: CCTexture2D: Using RGB565 texture since image has no alpha");
			pixelFormat = kCCTexture2DPixelFormat_RGB565;
		}
	}


	imageSize = CCSizeMake((float)(image->getWidth()), (float)(image->getHeight()));

	switch(pixelFormat) {          
		case kCCTexture2DPixelFormat_RGBA8888:
		case kCCTexture2DPixelFormat_RGBA4444:
		case kCCTexture2DPixelFormat_RGB5A1:
		case kCCTexture2DPixelFormat_RGB565:
		case kCCTexture2DPixelFormat_A8:
			tempData = (unsigned char*)(image->getData());
			CCAssert(tempData != NULL, "NULL image data.");

			if(image->getWidth() == (short)POTWide && image->getHeight() == (short)POTHigh)
			{
				data = new unsigned char[POTHigh * POTWide * 4];
				memcpy(data, tempData, POTHigh * POTWide * 4);
			}
			else
			{
				data = new unsigned char[POTHigh * POTWide * 4];
				memset(data, 0, POTHigh * POTWide * 4);

				unsigned char* pPixelData = (unsigned char*) tempData;
				unsigned char* pTargetData = (unsigned char*) data;

                int imageHeight = image->getHeight();
				for(int y = 0; y < imageHeight; ++y)
				{
					memcpy(pTargetData+POTWide*4*y, pPixelData+(image->getWidth())*4*y, (image->getWidth())*4);
				}
			}

			break;    
		case kCCTexture2DPixelFormat_RGB888:
			tempData = (unsigned char*)(image->getData());
			CCAssert(tempData != NULL, "NULL image data.");
			if(image->getWidth() == (short)POTWide && image->getHeight() == (short)POTHigh)
			{
				data = new unsigned char[POTHigh * POTWide * 3];
				memcpy(data, tempData, POTHigh * POTWide * 3);
			}
			else
			{
				data = new unsigned char[POTHigh * POTWide * 3];
				memset(data, 0, POTHigh * POTWide * 3);

				unsigned char* pPixelData = (unsigned char*) tempData;
				unsigned char* pTargetData = (unsigned char*) data;

				int imageHeight = image->getHeight();
				for(int y = 0; y < imageHeight; ++y)
				{
					memcpy(pTargetData+POTWide*3*y, pPixelData+(image->getWidth())*3*y, (image->getWidth())*3);
				}
			}
			break;   
		default:
			CCAssert(0, "Invalid pixel format");
	}

	// Repack the pixel data into the right format

	if(pixelFormat == kCCTexture2DPixelFormat_RGB565) {
		//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
		tempData = new unsigned char[POTHigh * POTWide * 2];
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;

		unsigned int length = POTWide * POTHigh;
		for(unsigned int i = 0; i < length; ++i, ++inPixel32)
		{
			*outPixel16++ = 
				((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) |  // R
				((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) |   // G
				((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);   // B
		}

		delete [] data;
		data = tempData;
	}
	else if (pixelFormat == kCCTexture2DPixelFormat_RGBA4444) {
		//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRGGGGBBBBAAAA"
		tempData = new unsigned char[POTHigh * POTWide * 2];
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;

		unsigned int length = POTWide * POTHigh;
		for(unsigned int i = 0; i < length; ++i, ++inPixel32)
		{
			*outPixel16++ = 
			((((*inPixel32 >> 0) & 0xFF) >> 4) << 12) | // R
			((((*inPixel32 >> 8) & 0xFF) >> 4) << 8) | // G
			((((*inPixel32 >> 16) & 0xFF) >> 4) << 4) | // B
			((((*inPixel32 >> 24) & 0xFF) >> 4) << 0); // A
		}

		delete [] data;
		data = tempData;
	}
	else if (pixelFormat == kCCTexture2DPixelFormat_RGB5A1) {
		//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGBBBBBA"
		tempData = new unsigned char[POTHigh * POTWide * 2];
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;

		unsigned int length = POTWide * POTHigh;
		for(unsigned int i = 0; i < length; ++i, ++inPixel32)
		{
			*outPixel16++ = 
			((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | // R
			((((*inPixel32 >> 8) & 0xFF) >> 3) << 6) | // G
			((((*inPixel32 >> 16) & 0xFF) >> 3) << 1) | // B
			((((*inPixel32 >> 24) & 0xFF) >> 7) << 0); // A
		}

		delete []data;
		data = tempData;
	}
	else if (pixelFormat == kCCTexture2DPixelFormat_A8)
	{
		// fix me, how to convert to A8
		pixelFormat = kCCTexture2DPixelFormat_RGBA8888;

		/*
		 * The code can not work, how to convert to A8?
		 *
		tempData = new unsigned char[POTHigh * POTWide];
		inPixel32 = (unsigned int*)data;
		outPixel8 = tempData;

		unsigned int length = POTWide * POTHigh;
		for(unsigned int i = 0; i < length; ++i, ++inPixel32)
		{
			*outPixel8++ = (*inPixel32 >> 24) & 0xFF;
		}

		delete []data;
		data = tempData;
		*/
	}

	if (data)
	{
		this->initWithData(data, pixelFormat, POTWide, POTHigh, imageSize);

		// should be after calling super init
		m_bHasPremultipliedAlpha = image->isPremultipliedAlpha();

		//CGContextRelease(context);
		delete [] data;
	}
	return true;
}

// implementation CCTexture2D (Text)
bool CCTexture2D::initWithString(const char *text, const char *fontName, float fontSize)
{
	return initWithString(text, CCSizeMake(0,0), CCTextAlignmentCenter, fontName, fontSize);
}
bool CCTexture2D::initWithString(const char *text, const CCSize& dimensions, CCTextAlignment alignment, const char *fontName, float fontSize)
{
#if CC_ENABLE_CACHE_TEXTTURE_DATA
    // cache the texture data
    VolatileTexture::addStringTexture(this, text, dimensions, alignment, fontName, fontSize);
#endif

	CCImage image;
    CCImage::ETextAlign eAlign = (CCTextAlignmentCenter == alignment) ? CCImage::kAlignCenter
        : (CCTextAlignmentLeft == alignment) ? CCImage::kAlignLeft : CCImage::kAlignRight;
    
    if (! image.initWithString(text, (int)dimensions.width, (int)dimensions.height, eAlign, fontName, (int)fontSize))
    {
        return false;
    }
    return initWithImage(&image);
}


// implementation CCTexture2D (Drawing)

void CCTexture2D::drawAtPoint(const CCPoint& point)
{
	GLfloat	coordinates[] = {	
		0.0f,	m_fMaxT,
		m_fMaxS,m_fMaxT,
		0.0f,	0.0f,
		m_fMaxS,0.0f };

	GLfloat	width = (GLfloat)m_uPixelsWide * m_fMaxS,
		height = (GLfloat)m_uPixelsHigh * m_fMaxT;

	GLfloat		vertices[] = {	
		point.x,			point.y,	0.0f,
		width + point.x,	point.y,	0.0f,
		point.x,			height  + point.y,	0.0f,
		width + point.x,	height  + point.y,	0.0f };

	glBindTexture(GL_TEXTURE_2D, m_uName);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void CCTexture2D::drawInRect(const CCRect& rect)
{
	GLfloat	coordinates[] = {	
		0.0f,	m_fMaxT,
		m_fMaxS,m_fMaxT,
		0.0f,	0.0f,
		m_fMaxS,0.0f };

	GLfloat	vertices[] = {	rect.origin.x,		rect.origin.y,							/*0.0f,*/
		rect.origin.x + rect.size.width,		rect.origin.y,							/*0.0f,*/
		rect.origin.x,							rect.origin.y + rect.size.height,		/*0.0f,*/
		rect.origin.x + rect.size.width,		rect.origin.y + rect.size.height,		/*0.0f*/ };

	glBindTexture(GL_TEXTURE_2D, m_uName);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

#ifdef CC_SUPPORT_PVRTC
// implementation CCTexture2D (PVRTC);    
bool CCTexture2D::initWithPVRTCData(const void *data, int level, int bpp, bool hasAlpha, int length, CCTexture2DPixelFormat pixelFormat)
{
	if( !(CCConfiguration::sharedConfiguration()->isSupportsPVRTC()) )
	{
		CCLOG("cocos2d: WARNING: PVRTC images is not supported.");
		this->release();
		return false;
	}

	glGenTextures(1, &m_uName);
	glBindTexture(GL_TEXTURE_2D, m_uName);

	this->setAntiAliasTexParameters();

	GLenum format;
	GLsizei size = length * length * bpp / 8;
	if(hasAlpha) {
		format = (bpp == 4) ? GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG : GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
	} else {
		format = (bpp == 4) ? GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG : GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
	}
	if(size < 32) {
		size = 32;
	}
	glCompressedTexImage2D(GL_TEXTURE_2D, level, format, length, length, 0, size, data);

	m_tContentSize = CCSizeMake((float)(length), (float)(length));
	m_uPixelsWide = length;
	m_uPixelsHigh = length;
	m_fMaxS = 1.0f;
	m_fMaxT = 1.0f;
    m_bHasPremultipliedAlpha = PVRHaveAlphaPremultiplied_;
    m_ePixelFormat = pixelFormat;

	return true;
}
#endif // CC_SUPPORT_PVRTC

bool CCTexture2D::initWithPVRFile(const char* file)
{
    bool bRet = false;
    // nothing to do with CCObject::init
    
    CCTexturePVR *pvr = new CCTexturePVR;
    bRet = pvr->initWithContentsOfFile(file);
        
    if (bRet)
    {
        pvr->setRetainName(true); // don't dealloc texture on release
        
        m_uName = pvr->getName();
        m_fMaxS = 1.0f;
        m_fMaxT = 1.0f;
        m_uPixelsWide = pvr->getWidth();
        m_uPixelsHigh = pvr->getHeight();
        m_tContentSize = CCSizeMake((float)m_uPixelsWide, (float)m_uPixelsHigh);
        m_bHasPremultipliedAlpha = PVRHaveAlphaPremultiplied_;
        m_ePixelFormat = pvr->getFormat();
                
        this->setAntiAliasTexParameters();
        pvr->release();
    }
    else
    {
        CCLOG("cocos2d: Couldn't load PVR image %s", file);
    }

    return bRet;
}

void CCTexture2D::PVRImagesHavePremultipliedAlpha(bool haveAlphaPremultiplied)
{
    PVRHaveAlphaPremultiplied_ = haveAlphaPremultiplied;
}

    
//
// Use to apply MIN/MAG filter
//
// implementation CCTexture2D (GLFilter)

void CCTexture2D::generateMipmap()
{
	CCAssert( m_uPixelsWide == ccNextPOT(m_uPixelsWide) && m_uPixelsHigh == ccNextPOT(m_uPixelsHigh), "Mimpap texture only works in POT textures");
	glBindTexture( GL_TEXTURE_2D, this->m_uName );
	ccglGenerateMipmap(GL_TEXTURE_2D);
}

void CCTexture2D::setTexParameters(ccTexParams *texParams)
{
	CCAssert( (m_uPixelsWide == ccNextPOT(m_uPixelsWide) && m_uPixelsHigh == ccNextPOT(m_uPixelsHigh)) ||
		(texParams->wrapS == GL_CLAMP_TO_EDGE && texParams->wrapT == GL_CLAMP_TO_EDGE),
		"GL_CLAMP_TO_EDGE should be used in NPOT textures");
	glBindTexture( GL_TEXTURE_2D, this->m_uName );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, texParams->minFilter );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, texParams->magFilter );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, texParams->wrapS );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, texParams->wrapT );
}

void CCTexture2D::setAliasTexParameters()
{
	ccTexParams texParams = { GL_NEAREST, GL_NEAREST, GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE };
	this->setTexParameters(&texParams);
}

void CCTexture2D::setAntiAliasTexParameters()
{
	ccTexParams texParams = { GL_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE };
	this->setTexParameters(&texParams);
}

//
// Texture options for images that contains alpha
//
// implementation CCTexture2D (PixelFormat)

void CCTexture2D::setDefaultAlphaPixelFormat(CCTexture2DPixelFormat format)
{
	g_defaultAlphaPixelFormat = format;
}


CCTexture2DPixelFormat CCTexture2D::defaultAlphaPixelFormat()
{
	return g_defaultAlphaPixelFormat;
}

unsigned int CCTexture2D::bitsPerPixelForFormat()
{
	unsigned int ret = 0;

	switch (m_ePixelFormat) 
	{
		case kCCTexture2DPixelFormat_RGBA8888:
			ret = 32;
			break;
		case kCCTexture2DPixelFormat_RGB565:
			ret = 16;
			break;
		case kCCTexture2DPixelFormat_A8:
			ret = 8;
			break;
		case kCCTexture2DPixelFormat_RGBA4444:
			ret = 16;
			break;
		case kCCTexture2DPixelFormat_RGB5A1:
			ret = 16;
			break;
		case kCCTexture2DPixelFormat_PVRTC4:
			ret = 4;
			break;
		case kCCTexture2DPixelFormat_PVRTC2:
			ret = 2;
			break;
		case kCCTexture2DPixelFormat_I8:
			ret = 8;
			break;
		case kCCTexture2DPixelFormat_AI88:
			ret = 16;
			break;
        case kCCTexture2DPixelFormat_RGB888:
            ret = 24;
            break;
		default:
			ret = -1;
			CCAssert(false, "illegal pixel format");
			CCLOG("bitsPerPixelForFormat: %d, cannot give useful result", m_ePixelFormat);
			break;
	}
	return ret;
}

#if ND_MOD
CCTexture2D* CCTexture2D::initWithPaletteData(const void* pData,
		CCTexture2DPixelFormat ePixelFormat, int nWidth, int nHeight,
		CCSize kSize, unsigned int uiSizeOfData)
{
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1, &m_uName);
	glBindTexture(GL_TEXTURE_2D, m_uName);

	setAntiAliasTexParameters();

	switch (ePixelFormat)
	{
	case kCCTexture2DPixelFormat_RGBA8888:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_RGBA, GL_UNSIGNED_BYTE, pData);
		break;
	case kCCTexture2DPixelFormat_RGBA4444:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, pData);
		break;
	case kCCTexture2DPixelFormat_RGB5A1:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, pData);
		break;
	case kCCTexture2DPixelFormat_RGB565:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, pData);
		break;
	case kCCTexture2DPixelFormat_AI88:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE,
				pData);
		break;
	case kCCTexture2DPixelFormat_A8:
		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, (GLsizei) nWidth,
				(GLsizei) nWidth, 0, GL_ALPHA, GL_UNSIGNED_BYTE, pData);
		break;
	case kCCTexture2DPixelFormat_RGBA8:
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_PALETTE8_RGBA8_OES, nWidth,
				nWidth, 0, uiSizeOfData, pData);
		break;
	default:
		//[NSException raise:NSInternalInconsistencyException format:@""];
		break;

	}

	m_tContentSize = kSize;
	m_uiWidth = (unsigned int) nWidth;
	m_uiHeight = (unsigned int) nHeight;
	m_ePixelFormat = ePixelFormat;
	m_fMaxT = m_tContentSize.width / (float) m_uiWidth;
	m_fMaxS = m_tContentSize.height / (float) m_uiHeight;
	m_bHasPremultipliedAlpha = false;
	m_pData = 0;
	m_nContainerType = 0;

	return this;
}

bool CCTexture2D::initWithPalettePNG(const char* pszPNGFile)
{
	if (0 == pszPNGFile || !*pszPNGFile)
	{
		return false;
	}

	FILE* pkFile = 0;
	unsigned int nPOTWide = 0;
	unsigned int nPOTHigh = 0;
	CCSize kImageSize;
	char szBuffer[PNG_BYTES_TO_CHECK] =
	{ 0 };

	if (0 == (pkFile = fopen(pszPNGFile, "rb")))
	{
		return false;
	}

	if (PNG_BYTES_TO_CHECK != fread(szBuffer, 1, PNG_BYTES_TO_CHECK, pkFile))
	{
		fclose(pkFile);
		return false;
	}

	if (0 != png_sig_cmp((unsigned char*) szBuffer, (png_size_t) 0,
					PNG_BYTES_TO_CHECK))
	{
		fclose(pkFile);
		return false;
	}

	png_structp pkPNGPointer = 0;
	png_infop pkPNGInfo = 0;
	unsigned int uiSigRead = PNG_BYTES_TO_CHECK;

	int nColorType = 0;
	int nInterlaceType = 0;
	png_uint_32 dwWidth = 0;
	png_uint_32 dwHeight = 0;
	int nPixelCount = 0;
	int nCompressionType = 0;
	int nFilterType = 0;

	pkPNGPointer = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);

	if (0 == pkPNGPointer)
	{
		fclose(pkFile);
		return false;
	}

	pkPNGInfo = png_create_info_struct(pkPNGPointer);

	if (0 == pkPNGInfo)
	{
		fclose(pkFile);
		png_destroy_read_struct(&pkPNGPointer, &pkPNGInfo, 0);
		return false;
	}

	png_init_io(pkPNGPointer, pkFile);
	png_set_sig_bytes(pkPNGPointer, uiSigRead);

	png_read_info(pkPNGPointer, pkPNGInfo);
	png_get_IHDR(pkPNGPointer, pkPNGInfo, &dwWidth, &dwHeight, &nPixelCount,
			&nColorType, &nInterlaceType, &nCompressionType, &nFilterType);
	CCConfiguration* pkConfig = CCConfiguration::sharedConfiguration();

	nPOTWide = dwWidth;
	nPOTHigh = dwHeight;

	unsigned int uiMaxTextureSize = pkConfig->getMaxTextureSize();

	if (nPOTHigh > uiMaxTextureSize || nPOTWide > uiMaxTextureSize)
	{
		release();
		fclose(pkFile);
		return false;
	}

	png_set_packing(pkPNGPointer);

	if ((PNG_COLOR_TYPE_GRAY == nColorType && nPixelCount < 8)
			|| PNG_COLOR_TYPE_PALETTE == nColorType)
	{
		png_set_expand(pkPNGPointer);
	}

	if (png_get_valid(pkPNGPointer, pkPNGInfo, PNG_INFO_tRNS))
	{
		png_set_tRNS_to_alpha(pkPNGPointer);
	}

	png_set_invert_mono(pkPNGPointer);
	png_set_swap(pkPNGPointer);
	//png_set_filter(pkPNGPointer, 0xFF, PNG_FILLER_AFTER);
	png_read_update_info(pkPNGPointer, pkPNGInfo);

	png_color* pkPalette = 0;
	int nNumberPalette = 0;
	int nPaletteLength = 1 << nPixelCount;
	RGBQUAD pBmiColors[256] =
	{ 0 };

	png_get_PLTE(pkPNGPointer, pkPNGInfo, &pkPalette, &nNumberPalette);

	if (0 < nNumberPalette)
	{

	}

	static void* s_pData = 0;
	CCTexture2DPixelFormat ePixelFormat = kCCTexture2DPixelFormat_Automatic;

	int nRowBytes = png_get_rowbytes(pkPNGPointer, pkPNGInfo);
	static png_bytepp s_pProwPointers = 0;
	int nMaxHeight = static_cast<int>(1024.0f * CC_CONTENT_SCALE_FACTOR());

	if (dwHeight > (unsigned int) nMaxHeight)
	{
		nMaxHeight = dwHeight;

		if (0 != s_pProwPointers)
		{
			free(s_pProwPointers);
			s_pProwPointers = 0;
		}
	}

	if (0 == s_pProwPointers)
	{
		s_pProwPointers = (png_bytepp) malloc(sizeof(png_bytep) * nMaxHeight);
	}

	int nMaxRowBytes = static_cast<int>(2048.0f * CC_CONTENT_SCALE_FACTOR());

	if (nRowBytes > nMaxRowBytes)
	{
		nMaxRowBytes = nRowBytes;

		if (0 == s_pData)
		{
			free(s_pData);
			s_pData = 0;
		}
	}

	if (0 == s_pData)
	{
		s_pData = malloc(sizeof(RGBQUAD) * 256 + nMaxRowBytes * nMaxHeight);
	}

	for (unsigned int row = 0; row < dwHeight; row++)
	{
		s_pProwPointers[row] = (png_byte*) s_pData + sizeof(RGBQUAD)
				+ nNumberPalette + row * nRowBytes;
	}

	if (0 < nNumberPalette)
	{
		memcpy(s_pData, (char*) pBmiColors, sizeof(RGBQUAD) * nNumberPalette);
		ePixelFormat = kCCTexture2DPixelFormat_RGBA8;
	}
	else if (32 == pkPNGPointer->pixel_depth)
	{
		ePixelFormat = kCCTexture2DPixelFormat_RGBA8888;
	}
	else
	{
		ePixelFormat = kCCTexture2DPixelFormat_RGB565;
	}

	png_read_image(pkPNGPointer, s_pProwPointers);
	png_read_end(pkPNGPointer, pkPNGInfo);

	if (32 == pkPNGPointer->pixel_depth)
	{
		for (int row = 0; row < (int) dwHeight; row++)
		{
			for (int col = 0;col < (int) dwWidth * 4;col += 4)
			{
				alpha_composite(s_pProwPointers[row][col],
					s_pProwPointers[row][col], s_pProwPointers[row][col + 3], 0);
				alpha_composite(s_pProwPointers[row][col+1],
					s_pProwPointers[row][col +1 ], s_pProwPointers[row][col + 3], 0);
				alpha_composite(s_pProwPointers[row][col+2],
					s_pProwPointers[row][col + 2], s_pProwPointers[row][col + 3], 0);
			}
		}
	}

	kImageSize = CCSizeMake(static_cast<float>(dwWidth), static_cast<float>(dwHeight));

	initWithPaletteData(s_pData, ePixelFormat, nPOTWide,nPOTHigh,
		kImageSize,sizeof(RGBQUAD) * nNumberPalette + nRowBytes + dwHeight);

	m_bHasPremultipliedAlpha = true;

	if (m_bKeepData)
	{
		m_pData = s_pData;
	}

	png_destroy_read_struct(&pkPNGPointer, &pkPNGInfo, png_infopp_NULL);

	fclose(pkFile);

	return true;
}

void CCTexture2D::SaveToBitmap(const char* pszPngFile,
		unsigned char** pBMPColorBuf, int rowByteWidth, int width, int height,
		int colorDepth, RGBQUAD* pPalette, int nPaletteLen)
{
	int mPackedRowByteWidth = (rowByteWidth + 3) & 0xfffffffc;
	BYTE *pBmpBuf = (BYTE*) malloc(
			mPackedRowByteWidth * height + 54 + nPaletteLen * sizeof(RGBQUAD));
	BITMAPFILEHEADER *pBfh = (BITMAPFILEHEADER *) pBmpBuf;
	BYTE* pTemp = pBmpBuf;
	*pTemp = 'B';
	pTemp++;
	*pTemp = 'M';

	pBfh->bfOffBits = 54 + nPaletteLen * sizeof(RGBQUAD);
	pBfh->bfSize = mPackedRowByteWidth * height + 54
	+ nPaletteLen * sizeof(RGBQUAD);
	pBfh->bfReserved1 = pBfh->bfReserved2 = 0;

	BITMAPINFOHEADER *pBih = (BITMAPINFOHEADER *) (pBfh + 1);
	pBih->biBitCount = colorDepth;
	pBih->biClrImportant = 0;
	pBih->biClrUsed = 0;
	pBih->biCompression = 0;
	pBih->biHeight = height;
	pBih->biPlanes = 1;
	pBih->biSize = 40;
	pBih->biSizeImage = mPackedRowByteWidth * height;
	pBih->biWidth = width;
	pBih->biXPelsPerMeter = 0;
	pBih->biYPelsPerMeter = 0;

	// copy palette
	BYTE *pRowBuf = (BYTE *) (pBih + 1);
	if (nPaletteLen > 0)
	{
		memcpy(pRowBuf, pPalette, nPaletteLen * sizeof(RGBQUAD));
		// copy data
		pRowBuf += nPaletteLen * sizeof(RGBQUAD);
	}

	pRowBuf += mPackedRowByteWidth * (height - 1);
	for (int i = 0; i < height; i++)
	{
		memcpy(pRowBuf, *pBMPColorBuf, rowByteWidth);
		pRowBuf -= mPackedRowByteWidth;
		pBMPColorBuf++;
	}
	//memcpy((BYTE *)(pBih+1),pBMPColorBuf,rowByteWidth * height);
	char szFileName[256] =
	{	0};
	sprintf(szFileName, "%stestJPG_PngLib.bmp", pszPngFile);
	WriteToBMPFile(szFileName, pBmpBuf,
			mPackedRowByteWidth * height + 54 + nPaletteLen * sizeof(RGBQUAD));
	free(pBmpBuf);
}

void CCTexture2D::WriteToBMPFile(char* pFileName, BYTE* pBmpBuf, int nBmplen)
{
	FILE* pkFile = fopen(pFileName, "wb");

	if (0 == pkFile)
	{
		return;
	}

	fwrite(pBmpBuf, nBmplen, 1, pkFile);
	fclose(pkFile);
}
#endif //ND_MOD

}

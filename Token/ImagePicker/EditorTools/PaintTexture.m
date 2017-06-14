#import "PaintTexture.h"

#import "PaintUtils.h"

@interface PaintTexture ()
{
    GLuint _textureName;
    
    GLubyte *_data;
    GLsizei _size;
    GLuint _width;
    GLuint _height;
    GLenum _type;
    GLenum _format;
    GLuint _rowByteSize;
    GLuint _unpackAlign;
}
@end

@implementation PaintTexture

+ (instancetype)textureWithImage:(UIImage *)image forceRGB:(bool)forceRGB
{
    return [[PaintTexture alloc] initWithCGImage:image.CGImage forceRGB:forceRGB];
}

- (instancetype)initWithCGImage:(CGImageRef)imageRef forceRGB:(bool)forceRGB
{
    self = [super init];
    if (self != nil)
    {
        [self _loadTextureFromCGImage:imageRef forceRGB:forceRGB];
    }
    return self;
}

- (void)dealloc
{
    if (_data != NULL)
        free(_data);
    
    PaintHasGLError();
}

- (void)cleanResources
{
    if (_textureName == 0)
        return;
    
    glDeleteTextures(1, &_textureName);
    _textureName = 0;
}

- (void)_loadTextureFromCGImage:(CGImageRef)image forceRGB:(bool)forceRGB
{
    bool isAlpha = forceRGB ? false : CGImageGetBitsPerPixel(image) == 8;
    
    _width = (GLuint) CGImageGetWidth(image);
    _height = (GLuint) CGImageGetHeight(image);
    _unpackAlign = isAlpha ? 1 : 4;
    _rowByteSize = _width * _unpackAlign;
    _data = malloc(_height * _rowByteSize);
    _type = GL_UNSIGNED_BYTE;
    _format = isAlpha ? GL_ALPHA : GL_RGBA;
    
    CGColorSpaceRef colorSpaceRef = isAlpha ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(_data, _width, _height, 8, _rowByteSize, colorSpaceRef, (isAlpha ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast));
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, _width, _height), image);
    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpaceRef);
}

static bool isPOT(int x)
{
    return (x & (x - 1)) == 0;
}

- (GLuint)textureName
{
    if (_textureName == 0)
    {
        PaintHasGLError();
        
        glGenTextures(1, &_textureName);
        glBindTexture(GL_TEXTURE_2D, _textureName);
        
        bool mipMappable = isPOT(_width) && isPOT(_height);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, mipMappable ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
    
        glPixelStorei(GL_UNPACK_ALIGNMENT, _unpackAlign);
        
        glTexImage2D(GL_TEXTURE_2D, 0, _format, _width, _height, 0, _format, _type, _data);
        PaintHasGLError();
        
        if (mipMappable)
        {
            glGenerateMipmap(GL_TEXTURE_2D);
            PaintHasGLError();
        }
    }
    
    return _textureName;
}

@end

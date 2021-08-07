//
//  Tool.m
//  MyEdutoHome
//
//  Created by junjie on 15-1-7.
//  Copyright (c) 2015年 chenjunjie. All rights reserved.
//

#import "Tool.h"
#import <CommonCrypto/CommonDigest.h>
//static Tool *myTool = nil;
#define ISFIRSTSTART @"isFirstStart"
@implementation Tool
+(NSString *)stringToMD5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    
    unsigned char result[16];
    
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    
    return [NSString stringWithFormat:
            
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            
            result[0], result[1], result[2], result[3],
            
            result[4], result[5], result[6], result[7],
            
            result[8], result[9], result[10], result[11],
            
            result[12], result[13], result[14], result[15]
            
            ];
}

+ (NSString *)md5:(NSString *)input {
    
    NSString *inputStr=[NSString stringWithFormat:@"%@{GZXTJY}",input];
    const char *cStr = [inputStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, strlen(cStr), result);
    
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}


+(NSMutableArray *)parseJsonArray:(NSString *)jsonString{
    if (!jsonString || [jsonString isEqual:[NSNull null]] || [jsonString isEqualToString:@""] || [jsonString isEqualToString:@"[]"] ) {
        return nil;
    }
    NSMutableString *strFile= [NSMutableString stringWithString:jsonString];
    NSMutableArray *arrayJson=[NSMutableArray arrayWithCapacity:42];
    NSRange leftRange;
    NSRange rightRange;
    leftRange=[strFile rangeOfString:@"["];
    leftRange.length=leftRange.location+1;
    leftRange.location=0;
    [strFile deleteCharactersInRange:leftRange];
    rightRange=[strFile rangeOfString:@"]"];
    rightRange.length=[strFile length]-rightRange.location;
    [strFile deleteCharactersInRange:rightRange];
    // NSLog(@"%@",strFile);
    while(1)
    {
        NSString *tempString;
        NSMutableDictionary *tempDictionary;
        rightRange=[strFile rangeOfString:@"}"];
        tempString=[strFile substringWithRange:NSMakeRange(0, rightRange.location+1)];
        NSData *tempData=[tempString dataUsingEncoding:NSUTF8StringEncoding];
        tempDictionary=[NSJSONSerialization JSONObjectWithData:tempData options:kNilOptions error:nil];
        [arrayJson addObject:tempDictionary];
        if([tempString isEqualToString:strFile])
            break;
        [strFile deleteCharactersInRange:NSMakeRange(0, rightRange.location+2)];
        
    }
    return arrayJson;
}

+(NSMutableArray*)string2aray:(NSString*)stringData
{
    NSData *jsonData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return array;
}

//是否为数字组成的串
+ (BOOL)isAllNum:(NSString *)port{
    unichar c;
    for (int i=0; i<port.length; i++) {
        c=[port characterAtIndex:i];
        if (!isdigit(c)) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isIPAddre:(const char*)p{
    int n[4];
    char c[4];
    if (sscanf(p, "%d%c%d%c%d%c%d%c",
               &n[0], &c[0], &n[1], &c[1],
               &n[2], &c[2], &n[3], &c[3])
        == 7)
    {
        int i;
        for(i = 0; i < 3; ++i)
            if (c[i] != '.')
                return 0;
        for(i = 0; i < 4; ++i)
            if (n[i] > 255 || n[i] < 0)
                return 0;
        return 1;
    } else
        return 0;
}

//16位MD5加密方式
+ (NSString *)getMd5_16Bit_String:(NSString *)srcString{
    //提取32位MD5散列的中间16位
    NSString *md5_32Bit_String=[self getMd5_32Bit_String:srcString];
    NSString *result = [[md5_32Bit_String substringToIndex:24] substringFromIndex:8];//即9～25位
    
    return result;
}

//32位MD5加密方式
+ (NSString *)getMd5_32Bit_String:(NSString *)srcString{
    const char *cStr = [srcString UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest );
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [result appendFormat:@"%02x", digest[i]];
    
    return result;
}
//sha1加密
+ (NSString*) sha1:(NSString *)content
{
    const char *cstr = [content cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:content.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

//获取当前时间
+(NSString *) getCurrentTimeToString:(NSString *)format
{
    NSDate *date = [NSDate date];
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:format];
    NSString *strTime = [df stringFromDate:currentDate];
    return strTime;
}

//根据date转为string
+(NSString *) dateToString:(NSDate *)date  withFormat:(NSString *)format
{
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:format];
    NSString *strTime = [df stringFromDate:currentDate];
    return strTime;
}

//根据string转位date
+(NSDate *) stringToDate:(NSString *)dateString withFormat:(NSString *)format
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    return [formatter dateFromString:dateString];
}

//
+(NSString *) getDocPath
{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [path objectAtIndex:0];
    
    return docDir;
}

//判断是否第一次启动app
+(BOOL) isFirstStartApp
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:ISFIRSTSTART]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ISFIRSTSTART];
        return true;
    }
    return false;
}

//按指定宽高压缩图片
+(UIImage *) imageCompressForSize:(UIImage *)sourceImage targetSize:(CGSize)size{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

//按指定宽压缩图片
+ (UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

//通过16进制数RGB获得颜色
+ (UIColor *)UIColorFromRGB: (NSInteger)rgbValue
{
    UIColor *rgbColor;
    
    rgbColor = [UIColor colorWithRed: ((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
                               green: ((float)((rgbValue & 0xFF00) >> 8)) / 255.0
                                blue: ((float)(rgbValue & 0xFF)) / 255.0
                               alpha: 1.0];
    
    return rgbColor;
}

//统计中英文混编的NSString字符串的长度
+  (int)chineseAndEnglishStringLength:(NSString*)strtemp {
    
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
    }
    return (strlength+1)/2;
    
}

//照片旋转90度
+(UIImage*)rotateImage:(UIImage *)image
{
    int kMaxResolution = 960; // Or whatever
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

//修复图片旋转
+ (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

//根据label内容长度获得高度
+(float)LableHeight:(UILabel*)lable
{
    CGRect txtFrame = lable.frame;
    lable.frame = CGRectMake(lable.frame.origin.x, lable.frame.origin.y, lable.frame.size.width,
                             txtFrame.size.height =[lable.text boundingRectWithSize:
                                                    CGSizeMake(txtFrame.size.width, CGFLOAT_MAX)
                                                                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                         attributes:[NSDictionary dictionaryWithObjectsAndKeys:lable.font,NSFontAttributeName, nil] context:nil].size.height);
    return txtFrame.size.height;
    
}
//为空判断
+(id)isNull:(NSString*)key
{
    if ([key isEqual:[NSNull null]]) {
        return @"";
    }
    else if (key == NULL) {
        return @"";
    }
    else if (key == nil) {
        return @"";
    }
    else if ([key isKindOfClass:[NSNull class]]){
        return @"";
    }
    else if ([key isEqualToString:@"(null)"] || [key isEqualToString:@"<null>"]
             ||[key isEqualToString:@""]){
        return @"";
    }
    else{
        return key;
    }
}

+(BOOL)stringIsNull:(NSString*)string
{
    if ([string isEqual:[NSNull null]]) {
        return YES;
    }
    else if (string == NULL) {
        return YES;
    }
    else if (string == nil) {
        return YES;
    }
    else if ([string isKindOfClass:[NSNull class]]){
        return YES;
    }
    else if ([string isEqualToString:@"(null)"] || [string isEqualToString:@"<null>"]
             ||[string isEqualToString:@""]){
        return YES;
    }
    else{
        return NO;
    }
}

//根据label内容长度获得宽度,高度
+(float)LableWidth:(UILabel *)lable
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];//这个frame是初设的，没关系，后面还会重新设置其size。
    [label setNumberOfLines:0];
    NSString *s = lable.text;
    UIFont *font = [UIFont fontWithName:@"Arial" size:12];
    CGSize size = CGSizeMake(320,2000);
    CGSize labelsize = [s sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
    return labelsize.width;
}

#pragma mark - 颜色转换 IOS中十六进制的颜色转换为UIColor
+ (UIColor *) colorWithHexString: (NSString *)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

//圆形图片
+(void) setCornerRadius:(UIView *)view
{
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = view.frame.size.width / 2;
    view.layer.borderWidth = 1;
    view.layer.borderColor = RGB(19, 150, 242).CGColor;
}


//语文：#d55858；数学：#58a8d6；英语：#d658bf；物理：#7b58d5；化学：#a158d5；生物：#58d595；地理：#58cbd5；历史：#d5a358；政治：#d57358；其他:#d5d5d5;
+(UIColor*)changeColor:(NSString*)subject
{
    if ([[Tool isNull:subject] isEqualToString:@""]) {
        return [Tool colorWithHexString:@"#00000000"];
    }
    if ([subject rangeOfString:@"语文"].location != NSNotFound) {
        return [Tool colorWithHexString:@"#009688"];
    }else if ([subject rangeOfString:@"数学"].location != NSNotFound){
        return [Tool colorWithHexString:@"#03a9f4"];
    }else if ([subject rangeOfString:@"英语"].location != NSNotFound){
        return [Tool colorWithHexString:@"#ff5722"];
    }else if ([subject rangeOfString:@"艺术"].location != NSNotFound){
        return [Tool colorWithHexString:@"#7b58d5"];
    }else if ([subject rangeOfString:@"科学"].location != NSNotFound){
        return [Tool colorWithHexString:@"#a158d5"];
    }else if ([subject rangeOfString:@"体育"].location != NSNotFound){
        return [Tool colorWithHexString:@"#673ab7"];
    }else if ([subject rangeOfString:@"音乐"].location != NSNotFound){
        return [Tool colorWithHexString:@"#ff9800"];
    }else if ([subject rangeOfString:@"美术"].location != NSNotFound){
        return [Tool colorWithHexString:@"#e91e63"];
    }else if ([subject rangeOfString:@"物理"].location != NSNotFound){
        return [Tool colorWithHexString:@"#ffc107"];
    }else if ([subject rangeOfString:@"化学"].location != NSNotFound){
        return [Tool colorWithHexString:@"#9c27b0"];
    }else if ([subject rangeOfString:@"生物"].location != NSNotFound){
        return [Tool colorWithHexString:@"#8bc34a"];
    }else if ([subject rangeOfString:@"政治"].location != NSNotFound){
        return [Tool colorWithHexString:@"#5677fc"];
    }else if ([subject rangeOfString:@"科学"].location != NSNotFound){
        return [Tool colorWithHexString:@"#259b24"];
    }else if ([subject rangeOfString:@"历史"].location != NSNotFound){
        return [Tool colorWithHexString:@"#3f51b5"];
    }else if ([subject rangeOfString:@"信息技术"].location != NSNotFound){
        return [Tool colorWithHexString:@"#cddc39"];
    }else if ([subject rangeOfString:@"劳动与技术"].location != NSNotFound){
        return [Tool colorWithHexString:@"#795548"];
    }else if ([subject rangeOfString:@"品德与生活"].location != NSNotFound){
        return [Tool colorWithHexString:@"#e51c23"];
    }else if ([subject rangeOfString:@"班主任"].location != NSNotFound){
        return [Tool colorWithHexString:@"#ffbb33"];
    }else if ([subject rangeOfString:@"其他"].location != NSNotFound){
        return [Tool colorWithHexString:@"#d5d5d5"];
    }
    return [Tool colorWithHexString:@"#d5d5d5"];
    
}


+(NSString *)prettyDateWithReference:(NSDate *)reference {
    NSString *suffix = @"ago";
    
    NSDate *date=[NSDate date];
    float different = [reference timeIntervalSinceDate:date];
    if (different < 0) {
        different = -different;
        suffix = @"from now";
    }
    
    // days = different / (24 * 60 * 60), take the floor value
    float dayDifferent = floor(different / 86400);
    
    int days   = (int)dayDifferent;
    //    int weeks  = (int)ceil(dayDifferent / 7);
    //    int months = (int)ceil(dayDifferent / 30);
    //    int years  = (int)ceil(dayDifferent / 365);
    
    // It belongs to today
    if (dayDifferent <= 0) {
        // lower than 60 seconds
        if (different < 60) {
            return @"刚刚";
        }
        
        // lower than 120 seconds => one minute and lower than 60 seconds
        if (different < 120) {
            return [NSString stringWithFormat:@"1分钟前"];
        }
        
        // lower than 60 minutes
        if (different < 660 * 60) {
            return [NSString stringWithFormat:@"%d分钟前", (int)floor(different / 60)];
        }
        
        // lower than 60 * 2 minutes => one hour and lower than 60 minutes
        if (different < 7200) {
            
            NSDate *date=[NSDate date];
            
            
            
            return [NSString stringWithFormat:@"1小时前"];
        }
        
        // lower than one day
        if (different < 86400) {
            return [NSString stringWithFormat:@"%d小时前", (int)floor(different / 3600)];
        }
    }
    // lower than one week
    else if (days < 7) {
        return [NSString stringWithFormat:@"%d天前", days];
    }
    //    // lager than one week but lower than a month
    //    else if (weeks < 4) {
    //        return [NSString stringWithFormat:@"%d week%@ %@", weeks, weeks == 1 ? @"" : @"s", suffix];
    //    }
    //    // lager than a month and lower than a year
    //    else if (months < 12) {
    //        return [NSString stringWithFormat:@"%d month%@ %@", months, months == 1 ? @"" : @"s", suffix];
    //    }
    //    // lager than a year
    else {
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        return [dateFormatter stringFromDate:reference];
    }
    
    return self.description;
}
//键入Done时，插入换行符，然后执行addBookmark
+ (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    //判断加上输入的字符，是否超过界限
    NSString *str = [NSString stringWithFormat:@"%@%@", textView.text, text];
    if (str.length > 10)
    {
        textView.text = [textView.text substringToIndex:10];
        return NO;
    }
    return YES;
}
/*由于联想输入的时候，函数textView:shouldChangeTextInRange:replacementText:无法判断字数，
 因此使用textViewDidChange对TextView里面的字数进行判断
 */
+ (void)textViewDidChange:(UITextView *)textView
{
    //该判断用于联想输入
    if (textView.text.length > 10)
    {
        textView.text = [textView.text substringToIndex:0];
    }
}
+(NSString *)returnNameWithCode:(NSString *)code
{
    NSString *schoolStr=@"121 122 130 132 133 123 221 222 223 224 225 411 126 128 226 227 125 129 127 134 421 ";
    
    if ([schoolStr rangeOfString:code].location!=NSNotFound) {
        return @"校园";
    }else
    {
        return @"办公";
    }
    return nil;
}


+ (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)jsonString{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

//字典转json格式字符串：

+ (NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSInteger)returnColorWithBeginTime:(NSString *)beginTime widthEndTime:(NSString *)endTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init]; //初始化格式器。
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];//定义时间为这种格式： YYYY-MM-dd hh:mm:ss 。
    NSString *currentTime = [formatter stringFromDate:[NSDate date]];//将NSDate  ＊对象 转化为 NSString ＊对象。
    
    NSString *nowString = [currentTime stringByReplacingOccurrencesOfString:@"-"withString:@""];
    nowString =[nowString stringByReplacingOccurrencesOfString:@":"withString:@""];
    nowString =[nowString stringByReplacingOccurrencesOfString:@" "withString:@""];
    NSInteger nowTime = [nowString integerValue];
    NSString *starTing = [beginTime stringByReplacingOccurrencesOfString:@"-"withString:@""];
    starTing =[starTing stringByReplacingOccurrencesOfString:@":"withString:@""];
    starTing =[starTing stringByReplacingOccurrencesOfString:@" "withString:@""];
    
    NSInteger startT = [starTing integerValue];
    NSString *finString = [endTime stringByReplacingOccurrencesOfString:@"-"withString:@""];
    finString =[finString stringByReplacingOccurrencesOfString:@":"withString:@""];
    finString =[finString stringByReplacingOccurrencesOfString:@" "withString:@""];
    
    NSInteger finT = [finString integerValue];
    
    if (nowTime < startT) {
        return 0;         //未进行
    }else  {
        if (nowTime<= finT) {
            return 1;     //进行中

        }else {
            
            return 2;     //已结束
        }
        
    }
    
    

}


@end

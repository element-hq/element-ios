//
//  Tool.h
//  MyEdutoHome
//
//  Created by junjie on 15-1-7.
//  Copyright (c) 2015年 chenjunjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Tool : NSObject
//+(id)shareInstance;
//用MD5加密字符串
+(NSString *)stringToMD5:(NSString *)str;

+ (NSString *)md5:(NSString *)str ;
//解析json数组
+(NSMutableArray *)parseJsonArray:(NSString *)jsonString;
+(NSMutableArray*)string2aray:(NSString*)stringData;
//是否为数字组成的串
+ (BOOL)isAllNum:(NSString *)port;
//判断IP输入是否合法
+ (BOOL)isIPAddre:(const char*)p;
//16位MD5加密方式
+ (NSString *)getMd5_16Bit_String:(NSString *)srcString;
//32位MD5加密方式
+ (NSString *)getMd5_32Bit_String:(NSString *)srcString;
//sha1加密
+ (NSString*) sha1:(NSString *)content;
//获取当前时间
+(NSString *) getCurrentTimeToString:(NSString *)format;
//根据date转为string
+(NSString *) dateToString:(NSDate *)date  withFormat:(NSString *)format;
//根据string转位date
+(NSDate *) stringToDate:(NSString *)dateString withFormat:(NSString *)format;
//获得doc目录
+(NSString *) getDocPath;
//是否第一次启动
+(BOOL) isFirstStartApp;
//按指定宽高压缩图片
+(UIImage *) imageCompressForSize:(UIImage *)sourceImage targetSize:(CGSize)size;
//按指定宽压缩图片
+ (UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth;
//通过16进制数RGB获得颜色
+ (UIColor *)UIColorFromRGB: (NSInteger)rgbValue;
//统计中英文混编的NSString字符串的长度
+ (int)chineseAndEnglishStringLength:(NSString*)strtemp;
//照片旋转90度
+(UIImage*)rotateImage:(UIImage *)image;
//修复图片旋转
+ (UIImage *)fixOrientation:(UIImage *)aImage;
//根据label内容长度获得宽度,高度
+(float)LableHeight:(UILabel*)lable;
+(float)LableWidth:(UILabel *)lable;
//为空判断
+(id)isNull:(NSString*)key;
+(BOOL)stringIsNull:(NSString*)string;
//圆形图片(长宽必须相等,加了一像素)
+(void) setCornerRadius:(UIView *)view;
//语文：#d55858；数学：#58a8d6；英语：#d658bf；物理：#7b58d5；化学：#a158d5；生物：#58d595；地理：#58cbd5；历史：#d5a358；政治：#d57358；其他:#d5d5d5;
+(UIColor*)changeColor:(NSString*)subject;
//16进制颜色方法
+ (UIColor *) colorWithHexString: (NSString *)color;

+(NSString *)prettyDateWithReference:(NSDate *)reference;

//根据code返回对应的模块名
+(NSString *)returnNameWithCode:(NSString *)code;


//键入Done时，插入换行符，然后执行addBookmark
+ (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
+ (void)textViewDidChange:(UITextView *)textView;

//字典转json
+ (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

//json转字典
+ (NSString*)dictionaryToJson:(NSDictionary *)dic;


+ (NSInteger)returnColorWithBeginTime:(NSString *)beginTime widthEndTime:(NSString *)endTime ;
@end

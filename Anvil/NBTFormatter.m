//
//  NBTFormatter.m
//  Anvil
//
//  Created by Ben K on 2013-01-24.
//
//

#import "NBTFormatter.h"

@interface NBTFormatter ()
- (NSNumber *)formattedNumberFromString:(NSString *)string;
- (BOOL)stringContainsLetters:(NSString *)string;
@end


@implementation NBTFormatter
@synthesize formatterType;

+ (NSFormatter *)formatterWithType:(NBTType)formatType
{
  // Can't format arrays, compounds or lists.
  if (formatType == NBTTypeByteArray || formatType == NBTTypeIntArray ||
      formatType == NBTTypeCompound || formatType == NBTTypeList) {
    return nil;
  }
  
  NBTFormatter *formatter = [[NBTFormatter alloc] init];
  [formatter setFormatterType:formatType];
  return [formatter autorelease];
}

- (NSString *)stringForObjectValue:(id)obj
{
  NSString	*retVal;
  
  if (obj == nil) {
    retVal = @"";
  } else if ([obj isKindOfClass:[NSNumber class]]) {
    retVal = [(NSNumber *)obj stringValue];
  } else {
    retVal = [NSString stringWithString:obj];
  }

  return retVal;
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
  *obj = [[string copy] autorelease];
  return YES;
}


- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error
{
  if (formatterType == NBTTypeString) {
    // Limit strings to 32 characters in length
    if ([partialString length] > 32) {
      NSBeep();
      return NO;
    }
  }
  
  // Format numbers
  if ([self stringContainsLetters:partialString]) {
    if (*error) *error = @"Numbers may not contain any letters.";
    NSBeep();
    return NO;
  }
  
  NSNumber *numberValue = [self formattedNumberFromString:partialString];
  if (formatterType == NBTTypeByte) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:INT8_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:INT8_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = partialString;
  }
  else if (formatterType == NBTTypeShort) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:INT16_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:INT16_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = [NSString stringWithFormat:@"%hd",[[self formattedNumberFromString:partialString] shortValue]];
  }
  else if (formatterType == NBTTypeInt) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:INT32_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:INT32_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = [NSString stringWithFormat:@"%i",[[self formattedNumberFromString:partialString] intValue]];
  }
  else if (formatterType == NBTTypeLong) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:INT64_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:INT64_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = [NSString stringWithFormat:@"%li",[[self formattedNumberFromString:partialString] longValue]];
  }
  
  else if (formatterType == NBTTypeFloat) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:FLT_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:FLT_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = [NSString stringWithFormat:@"%f",[[self formattedNumberFromString:partialString] floatValue]];
  }
  else if (formatterType == NBTTypeDouble) {
    NSComparisonResult resultMax = [numberValue compare:[NSNumber numberWithInt:DBL_MAX]];
    NSComparisonResult resultMin = [numberValue compare:[NSNumber numberWithInt:DBL_MIN]];
    if ((resultMax && resultMin) && (resultMax != NSOrderedAscending || resultMin != NSOrderedDescending)) {
      NSBeep();
      return NO;
    }
    *newString = [NSString stringWithFormat:@"%f",[[self formattedNumberFromString:partialString] doubleValue]];
  }
  
  return YES;
}

- (NSNumber *)formattedNumberFromString:(NSString *)string
{
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterNoStyle];
  NSNumber *myNumber = [formatter numberFromString:string];
  [formatter release];
  
  return myNumber;
}

- (BOOL)stringContainsLetters:(NSString *)string
{
  NSCharacterSet *nonNumbers;
  nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
  if ([string rangeOfCharacterFromSet:nonNumbers options:NSLiteralSearch].location != NSNotFound) {
    return YES;
  }
  return NO;
}


@end

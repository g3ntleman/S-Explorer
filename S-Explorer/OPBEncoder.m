

#import "OPBEncoder.h"


@implementation OPBEncoder {
    // Decoding:
//	OPTypeBlock typeBlock;
    
    NSMutableData* _encodingData;
}

//- (instancetype) initForDecodingWithTypeBlock: (OPBEncodedType (^)(NSArray* keyPath)) aTypeBlock {
//    if (self = [self init]) {
//        keyPath = [[NSMutableArray alloc] init];
//        typeBlock = aTypeBlock;
//    }
//    return self;
//}

- (instancetype) initForDecoding {
    if (self = [self init]) {
//        keyPath = [[NSMutableArray alloc] init];
    }
    return self;
}


- (instancetype) initForEncoding {
    if (self = [self init]) {
        _encodingData = [[NSMutableData alloc] initWithCapacity: 200];
    }
    return self;
}

- (void) advanceOffsetBy: (NSUInteger) diff {
    NSParameterAssert(_offset+diff <= _decodingData.length);
    _offset += diff;
}

- (void) setDecodingData: (NSData*) encodedData {
    _decodingData = [encodedData copy]; // make sure, this is immutable
    //bytes = [_decodingData bytes];
    //length = [_decodingData length];
    _offset = 0;
    //[keyPath removeAllObjects];
}

//  +(NSData *)encodeDataFromObject:(id)object
//
//  This method to returns an NSData object that contains the bencoded
//  representation of the object that you send. You can send complex structures
//  such as an NSDictionary that contains NSArrays, NSNumbers and NSStrings, and
//  the encoder will correctly serialise the data in the expected way.
//
//  Supports NSData, NSString, NSNumber, NSArray and NSDictionary objects.
//
//  NSStrings are encoded as NSData objects as there is no way to differentiate
//  between the two when decoding.
//
//  NSNumbers are encoded and decoded with their longLongValue.
//
//  NSDictionary keys must be NSStrings.

#define BUFFERLEN 37

//+ (NSData*) encodedDataFromObject: (id) object {
//    
//	NSMutableData* data = [NSMutableData data];
//	char buffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number.
//	
//	memset(buffer, 0, sizeof(buffer)); // Ensure the buffer is zeroed
//
//	if ([object isKindOfClass:[NSData class]]) 
//	{
//		// Encode a chunk of bytes from an NSData:
//		
//		snprintf(buffer, BUFFERLEN, "%lu:", (unsigned long)[object length]);
//
//		[data appendBytes:buffer length:strlen(buffer)];
//		[data appendData:object];
//
//		return data;
//	} 
//	if ([object isKindOfClass:[NSString class]]) 
//	{
//		// Encode an NSString:
//		
//		NSData *stringData = [object dataUsingEncoding:NSUTF8StringEncoding];
//		snprintf(buffer, BUFFERLEN, "%lu:", (unsigned long)[stringData length]);
//
//		[data appendBytes:buffer length:strlen(buffer)];
//		[data appendData:stringData];
//
//		return data;
//	} 
//	else if ([object isKindOfClass:[NSNumber class]]) 
//	{
//		// Encode an NSNumber:
//		
//		snprintf(buffer, BUFFERLEN, "i%llue", [object longLongValue]);
//
//		[data appendBytes:buffer length:strlen(buffer)];
//
//		return data;
//	}
//	else if ([object isKindOfClass:[NSArray class]]) 
//	{
//		// Encode an NSArray:
//		
//		[data appendBytes:"l" length:1];
//		
//		for (id item in object) {
//			[data appendData:[OPBEncoder encodedDataFromObject:item]];
//		}
//		
//		[data appendBytes:"e" length:1];
//		
//		return data;
//	}
//	else if ([object isKindOfClass:[NSDictionary class]]) 
//	{
//		// Encode an NSDictionary:
//		
//		[data appendBytes:"d" length:1];
//		
//		NSArray *sortedKeys = [[object allKeys] sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
//			return [obj1 compare:obj2 options:NSLiteralSearch];
//		}];
//		
//		for (id key in sortedKeys) {	
//			NSData *stringData = [key dataUsingEncoding:NSUTF8StringEncoding];
//			snprintf(buffer, BUFFERLEN, "%lu:", (unsigned long)[stringData length]);
//			
//			[data appendBytes:buffer length:strlen(buffer)];
//			[data appendData:stringData];
//			[data appendData:[OPBEncoder encodedDataFromObject:[object objectForKey:key]]];
//		}
//		
//		[data appendBytes:"e" length:1];
//		return data;
//	}
//
//	return nil;
//}

//+ (NSNumber*) numberFromEncodedData: (OPBEncoder*) data {
//    
//	NSMutableString *numberString = [NSMutableString string];
//	long long int	number;
//	
//	assert(data->bytes[data->offset] == 'i');
//	
//	data->offset++; // We start on the i so we need to move by one.
//	
//	while (data->offset < data->length && data->bytes[data->offset] != 'e') {
//		[numberString appendFormat:@"%c", data->bytes[data->offset++]];
//	}
//	
//	if (![[NSScanner scannerWithString:numberString] scanLongLong:&number]) 
//		return nil;
//	
//	data->offset++; // Always move the offset off the end of the encoded item.
//	
//	return [NSNumber numberWithLongLong:number];
//}
//
//- (id) decodedObject {
//	NSMutableString *dataLength = [NSMutableString string];
//	NSMutableData *decodedValue = [NSMutableData data];
//	
//	if (data->bytes[data->offset] < '0' | data->bytes[data->offset] > '9')
//		return nil; // Needed because we must fail to create a dictionary if it isn't a string.
//	
//	// strings are special; they start with a number so we don't move by one.
//	
//	while (data->offset < data->length && data->bytes[data->offset] != ':') {
//		[dataLength appendFormat:@"%c", data->bytes[data->offset++]];
//	}
//	
//	if (data->bytes[data->offset] != ':')
//		return nil; // We must have overrun the end of the bencoded string.
//	
//	data->offset++;
//	
//	[decodedValue appendBytes:data->bytes + data->offset length:[dataLength integerValue]];
//	[decodedValue increaseLengthBy:1];
//	data->offset += [dataLength integerValue]; // Always move the offset off the end of the encoded item.
//
//	BOOL isUTF8String = typeBlock && typeBlock(data->keyPath) == OPBEncodedStringType);
//	if (isUTF8String) return [NSString stringWithCString:[decodedValue bytes] encoding:NSUTF8StringEncoding];
//	
//	return decodedValue;
//}
//
//- (NSString*) decodedString {
//	/* A string is just bencoded data */
//	
//	id decodedData = [self decodedData];
//	
//	if (decodedData == nil) return nil;
//	if ([decodedData isKindOfClass: [NSString class]]) return decodedData;
//	
//	return [[NSString alloc] initWithData: decodedData encoding: NSUTF8StringEncoding];
//}
//
//+(NSArray *)arrayFromEncodedData:(OPBEncoder *)data
//{
//	NSMutableArray *array = [NSMutableArray array];
//	
//	assert(data->bytes[data->offset] == 'l');
//
//	data->offset++; // Move off the l so we point to the first encoded item.
//	
//	while (data->bytes[data->offset] != 'e') {
//		[array addObject:[OPBEncoder objectFromData:data]];
//	}
//
//	data->offset++; // Always move off the end of the encoded item.
//	
//	return array;
//}
//
//- (NSDictionary *) decodeDictionary {
//	NSDictionary *dictionary = [NSDictionary dictionary];
//	NSString *key = nil;
//	id value = nil;
//	
//	assert(data->bytes[data->offset] == 'd');
//	
//	data->offset++; // Move off the d so we point to the string key.
//	
//	while (data->bytes[data->offset] != 'e') {
//		if (data->bytes[data->offset] >= '0' && data->bytes[data->offset] <= '9') {
//			// Dictionaries are a bencoded string with a bencoded value.
//			key = [OPBEncoder stringFromEncodedData:data];
//			if (key) [data->keyPath addObject:key];
//			
//			value = [OPBEncoder objectFromData:data];
//			if (key != nil && value != nil) [dictionary setValue:value forKey:key];
//			
//			if (key) [data->keyPath removeLastObject];
//		}
//	}
//
//	data->offset++; // Move off the e so we point to the next encoded item.
//	
//	return dictionary;
//}
//

- (uint64) decodeInt {
    const void* bytes = _decodingData.bytes;
    const char* chars = bytes + _offset;
    const char* lastchar = bytes + MIN(_decodingData.length, _offset+BUFFERLEN-1);
    char buffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number.
    char* bufferChar = buffer;

    while (chars < lastchar && isdigit(*chars)) {
        *bufferChar = *chars;
        bufferChar++;
        chars++;
    }
    *bufferChar = 0;
    _offset = chars-(const char*)bytes;
    return atoi(buffer);
}

- (char) peek {
    return ((const char*)_decodingData.bytes)[_offset];
}

- (BOOL) decodeChar: (char) aChar {
    if (((const char*)_decodingData.bytes)[_offset]== aChar) {
        _offset++;
        return YES;
    }
    return NO;
}

- (NSString*) decodeStringOfLength: (NSUInteger) length {
    NSString* result = [[NSString alloc] initWithBytes: _decodingData.bytes + _offset length: length encoding: NSUTF8StringEncoding];
    _offset += length;
    return result;
}

- (id) decodeObject {
	/* Each of the decoders expect that the offset points to the first character
	 * of the encoded entity, for example the i in the bencoded integer "i18e" */
    
    if (_offset < _decodingData.length) {
        switch ([self peek]) {
            case 'l': {
                return [[NSArray alloc] initWithBencoder: self];
            }
            case 'd': {
                return [[NSDictionary alloc] initWithBencoder: self];
            }
            case 'i':
            case 'f': {
                return [[NSNumber alloc] initWithBencoder: self];
            }
            default:
                return [[NSString alloc] initWithBencoder: self];
        }
        
        // If we reach here, it doesn't appear that this is bencoded data. So, we'll
        // just return nil and advance to the next byte in the hopes we'll decode
        // something useful. Not sure if this is a good strategy.
        _offset++;
    }
	return nil;
}
//
//+(id)objectFromEncodedData:(NSData *)sourceData
//{
//	return [OPBEncoder objectFromEncodedData:sourceData withTypeAdvisor:nil];
//}
//
//
//
//
//+ (id) objectFromEncodedData: (NSData*) sourceData
//               withTypeBlock: (OPBEncodedType (^)(NSArray* keyPath)) block {
//    OPBEncoder* bencoder = [[self alloc] initWithData: sourceData typeBlock: block];
//	return [self objectFromData: bencoder];
//}
//
- (void) encodeBytes:(const void*) byteaddr length: (NSUInteger) aLength {
    NSAssert(_encodingData, @"encodingData not set, wrong init?");
    [_encodingData appendBytes: byteaddr length: aLength];
}


- (NSData*) encodeRootObject: (id<OPBencoding>) object {
    if (_encodingData) {
        [_encodingData setLength: 0];
    } else {
        _encodingData = [[NSMutableData alloc] init];
    }
    [object encodeWithBencoder: self];
    return self.encodingData;
}


+ (NSData*) encodedDataFromObject: (id <OPBencoding>) object {
    
    OPBEncoder* encoder = [[self alloc] initForEncoding];
    [encoder encodeRootObject: object];
    return encoder.encodingData;
}

+ (id <OPBencoding>) objectFromEncodedData: (NSData*) sourceData {
    
    OPBEncoder* decoder = [[self alloc] initForDecoding];
    decoder.decodingData = sourceData;
    return [decoder decodeObject];
}


@end

@implementation NSString (OPBEncodingSupport)

- (id) initWithBencoder:(OPBEncoder *)decoder {
    
    uint64 length = [decoder decodeInt];
    if ([decoder decodeChar: ':']) {
        return [decoder decodeStringOfLength: length];
    }
//
//    const void* bytes = decoder.decodingData.bytes;
//    const char* chars = bytes + decoder.offset;
//    const char* lastchar = bytes + decoder.decodingData.length;
//    uint64 length = 0;
//    while (chars < lastchar) {
//        if (*chars == ':') {
//            [decoder advanceOffsetBy: (chars+length)-(const char*)bytes];
//            chars++; // Skip colon
//            return [self initWithBytes: chars length: length encoding: NSUTF8StringEncoding];
//        }
//        assert(isdigit(*chars));
//        length = length * 10 + (*chars-'0');
//        chars++;
//    }
    return nil;
}

- (void) encodeWithBencoder: (OPBEncoder*) encoder {
    NSUInteger encodedLength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    char* charbuffer[encodedLength];
    [self getBytes: charbuffer maxLength: encodedLength usedLength: NULL encoding: NSUTF8StringEncoding options: 0 range: NSMakeRange(0,self.length) remainingRange: NULL];
    
    char lengthbuffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number +;
    memset(lengthbuffer, 0, sizeof(lengthbuffer)); // Ensure the buffer is zeroed - necessary?
    snprintf(lengthbuffer, BUFFERLEN, "%lu:", (unsigned long)encodedLength);
    [encoder encodeBytes: lengthbuffer length: strlen(lengthbuffer)];
    [encoder encodeBytes: charbuffer length: encodedLength];
}

@end

//@implementation NSData (OPBEncodingSupport)
//
//- (void) encodeWithBencoder: (OPBEncoder*) encoder {
//    char buffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number +;
//    memset(buffer, 0, sizeof(buffer)); // Ensure the buffer is zeroed - necessary?
//    snprintf(buffer, BUFFERLEN, "%lu:", (unsigned long)self.length);
//    [encoder encodeBytes: buffer length: strlen(buffer)];
//    [encoder encodeBytes: self.bytes length: self.length];
//
//}
//
//@end


@implementation NSNumber (OPBEncodingSupport)

- (id) initWithBencoder:(OPBEncoder *)decoder {
    
    id result = nil;
    if ([decoder decodeChar:'i']) {
        uint64 integer = [decoder decodeInt];
        if (! [decoder decodeChar:'e']) {
            [decoder decodeChar:'.'];
            NSUInteger prevOffset = decoder.offset;
            uint64 fraction = [decoder decodeInt];
            double doubleResult = integer + (fraction / pow(10, decoder.offset-prevOffset));
            result = [self initWithDouble: doubleResult];
        } else {
            result = [self initWithLongLong: integer];
        }
    }
    return result;
}
//
//    uint64 integer = [decoder decodeInt];
//    if (decoder.de)
//    
//    char buffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number.
//    char* bufferChar = buffer;
//    memset(buffer, 0, sizeof(buffer)); // Ensure the buffer is zeroed - necessary?
//    const void* bytes = decoder.decodingData.bytes;
//    const char* chars = bytes + decoder.offset;
//    const char* lastchar = bytes+decoder.decodingData.length;
//    const char* dot = NULL;
//    
//    NSAssert(*chars == 'i', @"Number Decoding Error.");
//    chars++;
//
//    while (chars < lastchar && (isdigit(*chars) || *chars == '.' || *chars == '-')) {
//        
//        if (*chars == '.') {
//            dot = chars;
//        }
//        *bufferChar = *chars;
//        chars++;
//        bufferChar++;
//    }
//    NSAssert(*chars == 'e', @"Number Decoding Error.");
//    [decoder advanceOffsetBy: chars-(const char*)bytes];
//    if (dot) {
//        double result = atof(buffer);
//        return [self initWithDouble: result];
//    } else {
//        uint64 result = atoi(buffer);
//        return [self initWithLongLong: result];
//    }
//}

- (void) encodeWithBencoder: (OPBEncoder*) encoder {
    
    char buffer[BUFFERLEN]; // Small buffer to hold length strings. Needs to hold a 64bit number.
    memset(buffer, 0, sizeof(buffer)); // Ensure the buffer is zeroed - necessary?

    // Encode an NSNumber:
    switch (self.objCType[0]) {
        case 'd': {
            snprintf(buffer, BUFFERLEN, "i%ge", [self doubleValue]);
            break;
        }
        default: {
            snprintf(buffer, BUFFERLEN, "i%llde", [self longLongValue]);
            break;
        }
    }
    [encoder encodeBytes:buffer length:strlen(buffer)];
}

@end

@implementation NSArray (OPBEncodingSupport)

- (id) initWithBencoder:(OPBEncoder *)decoder {
    
    NSMutableArray* result = nil;
    
    if ([decoder decodeChar:'l']) {
        
        result = [[NSMutableArray alloc] init];
        while (! [decoder decodeChar: 'e']) {
            id <OPBencoding> element = [decoder decodeObject];
            if (! element) break;
            [result addObject: element];
        }
    }
    return result;
}

- (void) encodeWithBencoder: (OPBEncoder*) encoder {
    
    [encoder encodeBytes: "l" length: 1];
    for (id <OPBencoding> object in self) {
        [object encodeWithBencoder: encoder];
    }
    [encoder encodeBytes: "e" length: 1];
}

@end

@implementation NSDictionary (OPBEncodingSupport)


- (id) initWithBencoder:(OPBEncoder *)decoder {
    
    NSMutableDictionary* result = nil;
    
    if ([decoder decodeChar:'d']) {
        result = [[NSMutableDictionary alloc] init];
        while (! [decoder decodeChar: 'e']) {
            NSString* key = [decoder decodeObject];
            if (! key) break;
            id <OPBencoding> value = [decoder decodeObject];
            if (! value) break;
            [result setObject: value forKey: key];
        }
    }
    return result;
}

- (void) encodeWithBencoder: (OPBEncoder*) encoder {
    
    // Encode an NSDictionary:
    [encoder encodeBytes: "d" length: 1];
    
    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSLiteralSearch];
    }];
    
    for (NSString* key in sortedKeys) {
        id <OPBencoding> value = [self objectForKey: key];
        [key encodeWithBencoder: encoder];
        [value encodeWithBencoder: encoder];
    }

    [encoder encodeBytes: "e" length: 1];
}

@end


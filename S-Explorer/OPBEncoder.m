

#import "OPBEncoder.h"


@implementation OPBEncoder {
    NSMutableData* _encodingData;
    BOOL _mutableContainers;
}

- (void) advanceOffsetBy: (NSUInteger) diff {
    NSParameterAssert(_offset+diff <= _decodingData.length);
    _offset += diff;
}

- (void) setDecodingData: (NSData*) encodedData {
    _decodingData = [encodedData copy]; // make sure, this is immutable
    _offset = 0;
}



#define BUFFERLEN 37



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

- (NSMutableString*) decodeStringOfLength: (NSUInteger) length {
    NSMutableString* result = [[NSMutableString alloc] initWithBytes: _decodingData.bytes + _offset length: length encoding: NSUTF8StringEncoding];
    _offset += length;
    return result;
}

- (id) decodeObject {
	/* Each of the decoders expect that the offset points to the first character
	 * of the encoded entity, for example the i in the bencoded integer "i18e" */
    
    if (_offset < _decodingData.length) {
        
        switch ([self peek]) {
            case 'l': {
                return [_mutableContainers ? [NSMutableArray alloc] : [NSArray alloc] initWithBencoder: self];
            }
            case 'd': {
                return [_mutableContainers ? [NSMutableDictionary alloc] : [NSDictionary alloc] initWithBencoder: self];
            }
            case 'i':
            case 'f': {
                return [[NSNumber alloc] initWithBencoder: self];
            }
            default:
                return [[NSMutableString alloc] initWithBencoder: self];
        }
        
        // If we reach here, it doesn't appear that this is bencoded data. So, we'll
        // just return nil and advance to the next byte and hopes we'll decode
        // something useful. Ok strategy?
        _offset++;
    }
	return nil;
}

- (void) encodeBytes:(const void*) byteaddr length: (NSUInteger) aLength {
    NSAssert(_encodingData, @"encodingData not set, wrong init?");
    [_encodingData appendBytes: byteaddr length: aLength];
}

//  NSNumbers are encoded and decoded with their longLongValue.
//  NSDictionary keys must be NSStrings.
- (NSData*) encodedDataFromObject: (id<OPBencoding>) object {
    if (_encodingData) {
        [_encodingData setLength: 0];
    } else {
        _encodingData = [[NSMutableData alloc] init];
    }
    [object encodeWithBencoder: self];
    return self.encodingData;
}


+ (instancetype) decoderForData: (NSData*) sourceData mutableContainers: (BOOL) mutable {
    id result = [[self alloc] init];
    [result setDecodingData: sourceData];
    [result setMutableContainers: mutable];
    return result;
}

/**
 * Defaults to immutable containers.
 */
+ (instancetype) decoderForData: (NSData*) sourceData {
    return [self decoderForData: sourceData mutableContainers: NO];
}

- (id <OPBencoding>) objectFromEncodedData: (NSData*) sourceData {
    self.decodingData = sourceData;
    return [self decodeObject];
}


@end

@implementation NSString (OPBEncodingSupport)

- (instancetype) initWithBencoder:(OPBEncoder *)decoder {
    
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

- (instancetype) initWithBencoder:(OPBEncoder *)decoder {
    
    id result = nil;
    if ([decoder decodeChar:'i']) {
        uint64 integer = [decoder decodeInt];
        if ([decoder decodeChar:'e']) {
            result = [self initWithLongLong: integer];
        } else {
            [decoder decodeChar:'.'];
            NSUInteger prevOffset = decoder.offset;
            uint64 fraction = [decoder decodeInt];
            double doubleResult = integer + (fraction / pow(10, decoder.offset-prevOffset));
            if ([decoder decodeChar:'e']) {
                result = [self initWithDouble: doubleResult];
            }
        }
    }
    return result;
}

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

- (instancetype) initWithBencoder:(OPBEncoder *)decoder {
    
    NSMutableArray* result = nil;
    
    if ([decoder decodeChar:'l']) {
        
        while (! [decoder decodeChar: 'e']) {
            id <OPBencoding> element = [decoder decodeObject];
            if (! element) return nil;
            if (! result) {
                result = [NSMutableArray array];
            }
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


- (instancetype) initWithBencoder: (OPBEncoder*) decoder {
    
    NSMutableDictionary* result = nil;
    
    if ([decoder decodeChar:'d']) {
        while (! [decoder decodeChar: 'e']) {
            NSString* key = [decoder decodeObject];
            if (! key) return nil;
            id <OPBencoding> value = [decoder decodeObject];
            if (! value) return nil;
            if (! result) {
                result = [[NSMutableDictionary alloc] init];
            }
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


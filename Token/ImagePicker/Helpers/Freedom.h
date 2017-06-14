// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#ifndef Freedom_h
#define Freedom_h

#import <Foundation/Foundation.h>
#import <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    const char *string;
    uint32_t key;
} FreedomIdentifier;
    
char *copyFreedomIdentifierValue(FreedomIdentifier identifier);
    
extern FreedomIdentifier FreedomIdentifierEmpty;
    
typedef struct {
    uint32_t name;
    IMP imp;
    FreedomIdentifier newIdentifier;
    FreedomIdentifier newEncoding;
} FreedomDecoration;
    
typedef struct {
    ptrdiff_t offset;
    int bit;
} FreedomBitfield;
    
void freedomInit();

Class freedomClass(uint32_t name);
Class freedomMakeClass(Class superclass, Class subclass);
ptrdiff_t freedomIvarOffset(Class targetClass, uint32_t name);
FreedomBitfield freedomIvarBitOffset(Class targetClass, uint32_t fieldName, uint32_t bitfieldName);
FreedomBitfield freedomIvarBitOffset2(Class targetClass, uint32_t fieldName, uint32_t bitfieldName);
void freedomSetBitfield(void *object, FreedomBitfield bitfield, int value);
int freedomGetBitfield(void *object, FreedomBitfield bitfield);
void freedomDumpBitfields(Class targetClass, void *object, uint32_t fieldName);
    
IMP freedomNativeImpl(Class targetClass, SEL selector);
void freedomClassAutoDecorate(uint32_t name, FreedomDecoration *classDecorations, int numClassDecorations, FreedomDecoration *instanceDecorations, int numInstanceDecorations);
IMP freedomImpl(id target, uint32_t name, SEL *selector);

#ifdef __cplusplus
}
#endif

#endif

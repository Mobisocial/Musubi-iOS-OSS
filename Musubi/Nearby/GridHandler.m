/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GridHandler.h"

static const double HALF_MERIDIANAL_CIRCUMFERENCE=2003.93*1000; //half meridianal circumference of the earth in meters
static const double RADIUS=6378100; //radius of the earth in meters
static const double CONVERSION = 3.2808399; // used to convert between meters and feet.


static float getDist(float x1, float y1, float x2, float y2){
    return (float)sqrt((x1-x2)*(x1-x2)+ (y1-y2)*(y1-y2));
}

static NSMutableArray* hexagonMap(float touchX, float touchY, int step){
    
    float sqrt3 = (float) sqrt(3);
    //int step = 100;
    float iStep = step*3;
    float jStep = (float)step*sqrt3;
    BOOL isTouched = YES;
    
    NSMutableArray* res = [NSMutableArray array];
    
    if(isTouched){
        float yIndex = fmod(touchY,iStep)/iStep;
        //System.err.println("touchY : " + touchY +" yIndex : " + yIndex);
        //Simple case
        if(yIndex <= 0.33 || (yIndex > 0.5 && yIndex < 0.83)){
            float lineBlock = touchY / iStep;
            //first row
            if(yIndex < 0.5){
                float xIndex = touchX / jStep;
                float hexX = (float)((int)xIndex) * jStep;
                float hexY = (float)((int)lineBlock) * iStep;
                //drawHexagon(hexX, hexY, step, canvas, true);
                [res addObject:[NSNumber numberWithFloat:hexX]]; 
                [res addObject:[NSNumber numberWithFloat:hexY]]; 
            }else //Second row
            {
                float xIndex = (touchX - (jStep/2)) / jStep;
                float hexX = (float)(((int)xIndex)+0.5) * jStep;
                float hexY = (float)(((int)lineBlock)+0.5 ) * iStep;
                //drawHexagon(hexX, hexY, step, canvas, true);
                [res addObject:[NSNumber numberWithFloat:hexX]]; 
                [res addObject:[NSNumber numberWithFloat:hexY]]; 
            }
        }else{
            if(yIndex < 0.5){
                float yNum = touchY / iStep;
                float xNum = touchX / jStep;
                
                float xAdder = (float)((int)xNum);
                float yAdder = (float)((int)yNum);
                
                float x1 = (float) (xAdder + 0.5);
                float y1 = (float) (yAdder + 0.165);
                float dist1 = getDist(x1, y1, xNum, yNum);
                
                float x2 = (float) (xAdder);
                float y2 = (float) (yAdder + 0.665);
                float dist2 = getDist(x2, y2, xNum, yNum);
                
                float x3 = (float) (xAdder + 1);
                float y3 = (float) (yAdder + 0.665);
                float dist3 = getDist(x3, y3, xNum, yNum);
                
                //System.err.println("xNum, yNum " + xNum + "," + yNum);
                //System.err.println("xAddr, yAddr " + xAdder + "," + yAdder);
                //System.err.println("x1, y1, dist1 " + x1 + "," + y1 + "," + dist1);
                //System.err.println("x2, y2, dist2 " + x2 + "," + y2 + "," + dist2);
                //System.err.println("x3, y3, dist3 " + x3 + "," + y3 + "," + dist3);
                
                if(dist1 < dist2){
                    if(dist1 < dist3){
                        //drawHexagon((x1-0.5f)*jStep, (y1-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x1-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y1-0.165f)*iStep]]; 
                    }
                    else{
                        //drawHexagon((x3-0.5f)*jStep, (y3-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x3-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y3-0.165f)*iStep]]; 
                    }
                }else{
                    if(dist2 < dist3){
                        //drawHexagon((x2-0.5f)*jStep, (y2-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x2-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y2-0.165f)*iStep]]; 
                    }else{
                        //drawHexagon((x3-0.5f)*jStep, (y3-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x3-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y3-0.165f)*iStep]]; 
                    }
                }
            }else{
                float yNum = touchY / iStep;
                float xNum = touchX / jStep;
                
                float xAdder = (float)((int)xNum);
                float yAdder = (float)((int)yNum);
                
                float x1 = (float) (xAdder + 0.5);
                float y1 = (float) (yAdder + 1.165);
                float dist1 = getDist(x1, y1, xNum, yNum);
                
                float x2 = (float) (xAdder);
                float y2 = (float) (yAdder + 0.665);
                float dist2 = getDist(x2, y2, xNum, yNum);
                
                float x3 = (float) (xAdder + 1);
                float y3 = (float) (yAdder + 0.665);
                float dist3 = getDist(x3, y3, xNum, yNum);
                
                //System.err.println("xNum, yNum " + xNum + "," + yNum);
                //System.err.println("xAddr, yAddr " + xAdder + "," + yAdder);
                //System.err.println("x1, y1, dist1 " + x1 + "," + y1 + "," + dist1);
                //System.err.println("x2, y2, dist2 " + x2 + "," + y2 + "," + dist2);
                //System.err.println("x3, y3, dist3 " + x3 + "," + y3 + "," + dist3);
                
                if(dist1 < dist2){
                    if(dist1 < dist3){
                        //drawHexagon((x1-0.5f)*jStep, (y1-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x1-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y1-0.165f)*iStep]]; 
                    }
                    else{
                        //drawHexagon((x3-0.5f)*jStep, (y3-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x3-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat: (y3-0.165f)*iStep]]; 
                    }
                }else{
                    if(dist2 < dist3){
                        //drawHexagon((x2-0.5f)*jStep, (y2-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x2-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y2-0.165f)*iStep]]; 
                    }else{
                        //drawHexagon((x3-0.5f)*jStep, (y3-0.165f)*iStep, step, canvas, true);
                        [res addObject:[NSNumber numberWithFloat:(x3-0.5f)*jStep]]; 
                        [res addObject:[NSNumber numberWithFloat:(y3-0.165f)*iStep]]; 
                    }
                }
            }
        }
    }
    return res;
}

static NSArray* getXYZ(double x, double y, int gridsize, int gridType){
    
    //Support for 3 grid types
    float sqrt3 = (float) sqrt(3);
    float step = gridsize;
    float iStep = step;
    float jStep = (float)step*sqrt3;
    
    double stripHeightPerDeg = HALF_MERIDIANAL_CIRCUMFERENCE/180.0;
    double roundoff_x=(int)abs(x)+ 0.5;
    double stripWidthPerDeg = (2*M_PI*RADIUS*cos(roundoff_x))/360.0;
    
    //System.err.println("x : " + x);
    double xDist = fmod(x,1.0);
    double xMod = x - xDist;
    //System.err.println("xDist : " + xDist);
    
    //System.err.println("stripHeightPerDeg : " + stripHeightPerDeg);
    xDist *= stripHeightPerDeg;
    //System.err.println("xDist : " + xDist);
    
    //System.err.println("y : " + y);
    y += 180;
    //System.err.println("y : " + y);
    //System.err.println("stripWidthPerDeg : " + stripWidthPerDeg);
    double yDist = y * stripWidthPerDeg;
    //System.err.println("yDist : " + yDist);
    
    switch(gridType){
		case 0:
			break;
		case 1:
			xDist -= 0.5*jStep;
			yDist -= 0.5*iStep;
			break;
		case 2:
			//x -= 0.5*jStep;
			yDist -= iStep;
			break;
    }
    
    NSMutableArray* res = hexagonMap((float)xDist, (float)yDist, gridsize);
    
    switch(gridType){
		case 0:
			break;
		case 1:
            [res replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:0]).floatValue +0.5*jStep]]; 
            [res replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:1]).floatValue +0.5*iStep]]; 
			break;
		case 2:
			//x -= 0.5*jStep;
            [res replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:1]).floatValue +iStep]]; 
			break;
    }
    
    [res replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:0]).floatValue /stripHeightPerDeg]]; 
    [res replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:0]).floatValue + xMod]]; 
    //System.err.println("res : " + res[0] + "," + res[1]);
    [res replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:((NSNumber*)[res objectAtIndex:1]).floatValue /stripWidthPerDeg]]; 
    //System.err.println("lat lon : " + res[0] + "," + res[1]);
    //return xyz;
    return res;
}


@implementation GridHandler
+ (NSArray*) hexTilesForSizeInFeet:(int)feet atLatitude:(double)latitude andLongitude:(double)longitude
{
    NSMutableArray* res = [NSMutableArray array];
    
    int gridsize_meters = (int) ((float)feet / CONVERSION); // All grids conversions are done in meters.
    
    //System.err.println("Location retrieved is : Latitude: " + mlatitude + "\t Longitude: " + mlongitude + "\t Grid size (in feet): " + gridsize_feet);
    
    
    
    long long latlon;
    NSArray* xyz;
    // Get all three grid types --- remember there are three grids that are overlapping that we need to check against. 
    xyz = getXYZ(latitude, longitude, gridsize_meters, 0);
    latlon = (long long)(((NSNumber*)[xyz objectAtIndex:0]).floatValue*1E6);
    latlon <<= 24;
    latlon |= (long long)(((NSNumber*)[xyz objectAtIndex:1]).floatValue*1E6);
    [res addObject:[NSNumber numberWithLongLong:latlon]];
    
    xyz = getXYZ(latitude, longitude, gridsize_meters, 1);
    latlon = (long long)(((NSNumber*)[xyz objectAtIndex:0]).floatValue*1E6);
    latlon <<= 24;
    latlon |= (long long)(((NSNumber*)[xyz objectAtIndex:1]).floatValue*1E6);
    [res addObject:[NSNumber numberWithLongLong:latlon]];
    
    xyz = getXYZ(latitude, longitude, gridsize_meters, 2);
    latlon = (long long)(((NSNumber*)[xyz objectAtIndex:0]).floatValue*1E6);
    latlon <<= 24;
    latlon |= (long long)(((NSNumber*)[xyz objectAtIndex:1]).floatValue*1E6);
    [res addObject:[NSNumber numberWithLongLong:latlon]];

    return res;
}
@end

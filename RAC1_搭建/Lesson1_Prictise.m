//
//  Lesson1_Prictise.m
//  RAC1_搭建
//
//  Created by 吴书敏 on 16/10/21.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "Lesson1_Prictise.h"

int max(int *array, int count)
{
//    int max = array[0]; // 任何变量不允许第二次赋值
//    for (int i = 0; i < count; i++) {
//        if (array[i] > max) {
//            max = array[i];
//        }
//    }
//    
//    return max;
    
    if (count < 1) {
        return INT_MIN;
    }
    
    if (count == 1) {
        return array[0];
    }
    
    // count = 2 时
    int temp = max(array + 1, count - 1);
    // 当前数组第一个元素与 max返回值比
    return array[0] > temp ? array[0] : temp;
}


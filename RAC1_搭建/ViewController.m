//
//  ViewController.m
//  reactivecocoa_practise
//
//  Created by ZangChengwei on 16/6/19.
//  Copyright © 2016年 ZangChengwei. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *spirit;
@property (weak, nonatomic) IBOutlet UIView *grid;
@property (weak, nonatomic) IBOutlet UIButton *autoRunBtn;
@property (weak, nonatomic) IBOutlet UIButton *oneStepBtn;

@end

static int GridXBlocks = 13;
static int GridYBlocks = 7;

typedef NS_ENUM(NSUInteger, SpiritState) {
    SpiritStateAppear,
    SpiritStateRunning,
    SpiritStateDisappear,
};


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *img1 = [UIImage imageNamed:@"pet1"];
    UIImage *img2 = [UIImage imageNamed:@"pet2"];
    UIImage *img3 = [UIImage imageNamed:@"pet3"];
    
    self.spirit.animationImages = @[img1, img2, img3];
    self.spirit.animationDuration = 1.0;
    [self.spirit startAnimating];
    
    // 方向坐标
    NSArray *steps = @[RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0), RACTuplePack(@0, @1),
                       RACTuplePack(@0, @1), RACTuplePack(@0, @1),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@0, @-1), RACTuplePack(@0, @-1),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0)
                       ];
    
    RACTuple *startBlock = RACTuplePack(@1, @2);
    
    RACSequence *stepsSequence = steps.rac_sequence;
    
    NSInteger spiritCount = steps.count + 1; // 步数 + 1个起始位置
    
    void (^updateXYConstraints)(UIView *view, RACTuple *location) = ^(UIView *view, RACTuple *location) {
        CGFloat width = self.grid.frame.size.width / GridXBlocks;
        CGFloat height = self.grid.frame.size.height / GridYBlocks;
        CGFloat x = [location.first floatValue] * width;
        CGFloat y = [location.second floatValue] * height;
        view.frame = CGRectMake(x, y, width, height);
    };
    
    for (int i = 1; i < spiritCount + 1; ++i) {
        UIImageView *spiritView = [[UIImageView alloc] init];
        
        spiritView.tag = i;
        spiritView.animationImages = @[img1, img2, img3];
        spiritView.animationDuration = 1.0;
        spiritView.alpha = 0.0f;
        [self.grid addSubview:spiritView];
        
        updateXYConstraints(spiritView, startBlock);
    }
    
    
   // stepSignal
    RACSignal *stepSignal = [stepsSequence.signal scanWithStart:startBlock reduce:^id(RACTuple *running, RACTuple *next) {
        RACTupleUnpack(NSNumber *x1, NSNumber *y1) = running;
        RACTupleUnpack(NSNumber *x2, NSNumber *y2) = next;
        return RACTuplePack(@(x1.integerValue + x2.integerValue),
                            @(y1.integerValue + y2.integerValue));
    }]; // 这里先不要 startWith :startBlock 因为第一步不需要延迟，做完延迟再拼接头
    
    // 每一秒挪动一步
    stepSignal = [[stepSignal map:^id(id value) {
        return [[RACSignal return:value] delay:1];
    }] concat]; // map 只做了替换，但时间上没有变化，还是紧挨着。需要逐个拼接起来。
    
    // 起始信号 concat: run信号 ： 终止信号
    
    // 一个行走的信号好了，下面要发送多个行走信号。不同行走信号的tag值不同。写一个函数或者block封装起来。
    // ps：idx 只起到tag值作用。一个头一个尾 就足够了
    RACSignal *(^newSpiritSignal)(NSNumber *idx) = ^RACSignal *(NSNumber *idx) {
       return [[[RACSignal return:RACTuplePack(idx,
                                                                     @(SpiritStateAppear),
                                                                     startBlock)] concat:
                                      [stepSignal map:^id(RACTuple *xy) {
            return RACTuplePack(idx, @(SpiritStateRunning), xy);
        }]] concat:[RACSignal return:RACTuplePack(idx, @(SpiritStateDisappear), nil)]];
        
    };
    
    // 从 1 ~ spiritCount
    // 创建一个1.5 间隔的信号，取 spiritCount 个
    RACSignal *timerSignal = [[RACSignal interval:1.5 onScheduler:[RACScheduler mainThreadScheduler]] take:spiritCount];
    // 把时间信号变换为数字信号
    RACSignal *counterSignal = [timerSignal scanWithStart:@0 reduce:^id(NSNumber *num, id next) {
        return @(num.integerValue + 1);
    }];
    
    //
    RACSignal *autoBtnClickSignal = [[self.autoRunBtn rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@"A"];
    RACSignal *oneStepClicSignal = [[self.oneStepBtn rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@"M"];
    
    RACSignal *clickSignal = [RACSignal merge:@[autoBtnClickSignal, oneStepClicSignal]];
    
    clickSignal = [[[clickSignal scanWithStart:@"" reduce:^id(id running, id next) {
        // 已点击A 又点击 A 则，返回空，否则返回 next
        if ([running isEqualToString:@"A"] && [next isEqualToString:@"A"]) {
            return @"";
        }
        return next;
    }] map:^id(id value) {
        if([value isEqualToString:@"A"]) { return timerSignal;}
        if([value isEqualToString:@"M"]) { return [RACSignal return:nil];} // nil 任意一个信号，有值的,单点（可以认为占位）
        return [RACSignal empty]; // 空信号，只alloc init 没有值，
    }] switchToLatest];
    
    // 循环 tag idx
    RACSignal *runSignal = [clickSignal scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
        NSInteger idx = running.integerValue;
        idx++;
        if (idx == spiritCount) {
            idx = 1;
        }
        return @(idx);
    }];
    
    /**
     *  结题思路
     *  1. scan 方向坐标变为 绝对坐标
     *  2. map delay concat 得到时间间隔为 1 秒的绝对坐标
     *  3. 封装了一个block 根据idx 得到 移动Tulple
     *  4. 创建一个timer信号，并把 timer 信号变为数字信号
     *  5. mapReplace 点击信号，merge两个信号，A & A 返回 空，否则返回 next
     *  6. map 替换 A 为 1.5 秒 时间信号 替换 M 为单点信号， 否则返回 empty，并 switchToLast降阶
     *  7. scan clickSignal，变为数字信号， flattenMap 得到 坐标信号。
     */
    
    
    
    
    /*
    // autoRunBtnSignal
    RACSignal *autoRunBtnSignal = [self.autoRunBtn rac_signalForControlEvents:UIControlEventTouchUpInside];
    
    // oneStepBtnSignal
    RACSignal *oneStepBtnSignal = [self.oneStepBtn rac_signalForControlEvents:UIControlEventTouchUpInside];
    
   // 1s timerSignal
    RACSignal *oneTimer = [RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]];
    RACSignal *oneHalfTimer = [RACSignal interval:1.5 onScheduler:[RACScheduler mainThreadScheduler]];
    
   // 自动按钮点击后 每1.5 秒产生一个信号，再次点击，停止信号
    RACSignal *autoRunSignal = [[[autoRunBtnSignal take:1] concat:oneHalfTimer] takeUntil:[autoRunBtnSignal skip:1]];
    
    // intervalStepSignal 每 1 秒 挪动一步
    RACSignal *intervalStepSignal = [[stepSignal zipWith:oneTimer] reduceEach:^id(RACTuple *xy, id _){
        return xy;
    }];
    
    // 处理 intervalStepSignal 附加 tag status
    intervalStepSignal = [intervalStepSignal scanWithStart:RACTuplePack(@-1, @0,nil) reduce:^id(RACTuple *info, RACTuple *xy) {
        NSNumber *idx = info.first;
        NSInteger intIdx = idx.integerValue + 1;
        NSNumber *status = @(SpiritStateRunning);
        return RACTuplePack(@(intIdx), status, xy);
    }];
    
    // autoRunBtnSignal 1.5 秒发送一个 intervalStepSignal，信号的信号高阶信号
    autoRunSignal = [[autoRunSignal mapReplace:intervalStepSignal] flatten];
     */
    
    // 数字信号flattenMap 变为 移动信号
    RACSignal *spiritRunSignal = [runSignal flattenMap:newSpiritSignal];
    @weakify(self)
    [[spiritRunSignal deliverOnMainThread] subscribeNext:^(RACTuple *info) {
        @strongify(self)
        RACTupleUnpack(NSNumber *idx, NSNumber *state, RACTuple *xy) = info;
        SpiritState stateValue = state.unsignedIntegerValue;
        NSInteger idxValue = idx.integerValue;
        UIImageView *spirit = [self.grid viewWithTag:idxValue];
        
        switch (stateValue) {
            case SpiritStateAppear:
            {
                updateXYConstraints(spirit, xy);
                [UIView animateWithDuration:1 animations:^{
                    spirit.alpha = 1.0f;
                }];
                [spirit startAnimating];
            }
                break;
            case SpiritStateRunning:
            {
                
                [UIView animateWithDuration:1 animations:^{
                    updateXYConstraints(spirit, xy);
                }];
            }
                break;
            case SpiritStateDisappear:
            {
                [UIView animateWithDuration:1 animations:^{
                    spirit.alpha = 0.0f;
                } completion:^(BOOL finished) {
                    [spirit stopAnimating];
                }];
                
            }
                break;
            default:
                break;
        }
        
        
    }];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

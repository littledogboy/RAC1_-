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
    RACSignal *stepSignal = @[RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                              RACTuplePack(@1, @0), RACTuplePack(@0, @1),
                              RACTuplePack(@0, @1), RACTuplePack(@0, @1),
                              RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                              RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                              RACTuplePack(@0, @-1), RACTuplePack(@0, @-1),
                              RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                              RACTuplePack(@1, @0)
                              ].rac_sequence.signal;
    //  初始位置
    RACTuple *startBlock = RACTuplePack(@1, @2);
    
    //  方向坐标 -> （实际坐标）
    stepSignal =  [[[stepSignal scanWithStart:startBlock reduce:^id(RACTuple *last, RACTuple *direction) {
        RACTupleUnpack(NSNumber *x1, NSNumber *y1) = last;
        RACTupleUnpack(NSNumber *x2, NSNumber *y2) = direction;
        NSNumber *x = @(x1.integerValue + x2.integerValue);
        NSNumber *y = @(y1.integerValue + y2.integerValue);
        return RACTuplePack(x, y); // 新信号中的值
    }] startWith:startBlock] collect];
    
    // 自动点击信号
    RACSignal *autoClickSignal = [self.autoRunBtn rac_signalForControlEvents:UIControlEventTouchUpInside];
    // 用户点击信号
    RACSignal *oneStepClickSignal = [self.oneStepBtn rac_signalForControlEvents:UIControlEventTouchUpInside];
    // 按时间 timer 信号
    RACSignal *timerSignal = [RACSignal interval:0.5 onScheduler:[RACScheduler mainThreadScheduler]];
    // 空信号（相当于有next值的一个占位符）
    RACSignal *idSignal = [RACSignal return:nil];
    
    // 生阶操作，把点击返回值 --》 点击返回 信号
    RACSignal *autoRunButtonClickSignal = [autoClickSignal mapReplace:timerSignal];
    RACSignal *oneStepButtonClickSignal = [oneStepClickSignal mapReplace:idSignal];
    // 两个信号之间的切换 switchToLatest, 切换到最近一个并阻断上一个
    RACSignal *oneStepAutoSignal = [[autoRunButtonClickSignal merge:oneStepButtonClickSignal] switchToLatest];
    
    RACSignal *spiritRunSignal = [[[[stepSignal concat:[RACSignal never]] sample:oneStepAutoSignal] scanWithStart:RACTuplePack(nil, @0) reduce:^id(RACTuple *value, NSArray *steps) {
        // 每次获取的都是 一个 tuple 一个原来的array
        // runing next
        NSNumber *idx = value.second; // 当前下标值，从0开始
        NSInteger nextIdx = (idx.integerValue + 1) % steps.count; // 下个下标
        // 下个下标元素， 下个下标
        return RACTuplePack(steps[nextIdx], @(nextIdx));
    }] reduceEach:^id(NSArray *steps, id _){
        return steps;
    }];
    
    // 点击之后，才开始 1 秒间隔的连续信号 zip 组合最新的。
    // 点击开始： take concat  停止：takeUntil skip 跳过第1个 再次点击的信号
//    RACSignal *autoStepSignal =  [[[autoClickSignal take:1] concat:timerSignal] takeUntil:[autoClickSignal skip:1]];
    
    // 信号组合 zip merge combinelatest sample concat
    // 把 stepSignal 和 timer 进行一个 zip,zip 发送的比较晚的控制时间
//    RACSignal *spiritRunSignal = [[stepSignal zipWith:oneStepClickSignal] reduceEach:^id(RACTuple *xy, id _){
//        return xy; // 我们要取的值是第一个值 stepSignal 的值，第二个控制时间的并不关心
//    }];
    
    @weakify(self)
    [spiritRunSignal subscribeNext:^(RACTuple *xy) {
        @strongify(self)
        RACTupleUnpack(NSNumber *x, NSNumber *y) = xy;
        CGFloat spiritHeight = self.grid.frame.size.height / GridYBlocks;
        CGFloat spiritWidth = self.grid.frame.size.width / GridXBlocks;
        [UIView animateWithDuration:0.5 animations:^{
            self.spirit.frame = CGRectMake(spiritWidth * x.integerValue, spiritHeight * y.integerValue, spiritWidth, spiritHeight);
        }];
        
    }];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  ACPageScrollView.h
//  ArtCalendar
//
//  Created by chenyan on 2018/3/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//  轮播图控件

#import <UIKit/UIKit.h>
@class ACPageScrollView;


@protocol ACPageScrollViewDataSource<NSObject>

@required

- (NSInteger)numberOfPagesInACPageScrollView:(ACPageScrollView *)pageScrollView;

- (UICollectionViewCell *)ACPageScrollView:(ACPageScrollView *)pageScrollView cellForPageAtIndex:(NSInteger)index;

@end


@protocol ACPageScrollViewDelegate<NSObject>

@optional
- (void)ACPageScrollView:(ACPageScrollView *)pageScrollView willDisplayCellForItemAtIndex:(NSInteger)index;

- (void)ACPageScrollView:(ACPageScrollView *)pageScrollView didDisplayCellForItemAtIndex:(NSInteger)index;

- (void)ACPageScrollView:(ACPageScrollView *)pageScrollView didChangedPageControlToIndex:(NSInteger)index;

- (void)ACPageScrollView:(ACPageScrollView *)pageScrollView didSelectItemAtIndex:(NSInteger)index;
 
@end


@interface ACPageScrollView : UIView

@property (nonatomic, weak) id<ACPageScrollViewDataSource> dataSource;

@property (nonatomic, weak) id<ACPageScrollViewDelegate> delegate;

/** default is no */
@property (nonatomic, assign, getter=isPageControlHidden) BOOL pageControlHidden;

/** default is yes */
@property (nonatomic, assign) BOOL userScrollEnable;

/** If the totol number is 0  or 1 ,  you can't set the autoScroll to YES. */
@property (nonatomic, assign) BOOL autoScroll;
 
@property (nonatomic, assign) NSTimeInterval timeInterval;

/** default is lightGray */
@property (nonatomic, strong) UIColor *currentPageIndicatorTintColor;

/** default is white */
@property (nonatomic, strong) UIColor *pageIndicatorTintColor;



- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)reuserIdentifier;

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forPageAtIndex:(NSInteger)index;

- (void)reloadData;

@end




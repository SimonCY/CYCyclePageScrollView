//
//  ACPageScrollView.m
//  ArtCalendar
//
//  Created by chenyan on 2018/3/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "ACPageScrollView.h"
#import "CYDispatchTimer.h"

#define ACPageScrollViewDefaultTimeInterval 6

@interface ACPageScrollView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, weak) UIPageControl *pageControl;

@property (nonatomic, copy) NSString *timerName;

@property (nonatomic, assign) NSInteger numberOfPages;

//this property are used to pagecontrol
@property (nonatomic, assign) NSInteger currentPage;

@end


@implementation ACPageScrollView

#pragma mark - system

- (instancetype)initWithFrame:(CGRect)frame {
  
  if (self = [super initWithFrame:frame]) {
    
    //collectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    collectionView.pagingEnabled = YES;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.scrollsToTop = NO;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.bounces = NO;
    
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    //pageControl
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    [pageControl setCurrentPageIndicatorTintColor:[UIColor lightGrayColor]];
    [pageControl setPageIndicatorTintColor:[UIColor whiteColor]];
    pageControl.layer.shadowOffset = CGSizeMake(0.1, 0.1);
    pageControl.layer.shadowOpacity = 0.1;
    pageControl.layer.shadowColor = [UIColor blackColor].CGColor;
    [self addSubview:pageControl];
    self.pageControl = pageControl;
    
    self.currentPage = 0;
    self.numberOfPages = 0;
 
    self.autoScroll = YES;
    self.timeInterval = ACPageScrollViewDefaultTimeInterval;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.collectionView.frame = self.bounds;
  self.pageControl.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.96);
}

#pragma mark - public

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)reuserIdentifier {
  
  [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:reuserIdentifier];
}

- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forPageAtIndex:(NSInteger)index {
  
  return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)reloadData {
  
  [self stop];
  
  self.numberOfPages = [self.dataSource numberOfPagesInACPageScrollView:self];
  NSAssert(self.numberOfPages >= 0, @"ACPageScrollView :number of page can't be a minus");
  self.currentPage = 0;
  self.pageControl.numberOfPages = self.numberOfPages;
  
  [self.collectionView reloadData];
  
  dispatch_async(dispatch_get_main_queue(), ^{
   
    //刷新完成
    if (self.numberOfPages > 1) {
      
      [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.numberOfPages * 700 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
      if (self.autoScroll) {
        
        [self start];
      }
    }
  });
}

#pragma mark - getter

- (UICollectionViewCell *)cellForPageAtIndex:(NSInteger)index {
  
  return [self.dataSource ACPageScrollView:self cellForPageAtIndex:index];
}


#pragma mark - setter

- (void)setUserScrollEnable:(BOOL)userScrollEnable {
  _userScrollEnable = userScrollEnable;
  
  self.collectionView.scrollEnabled = _userScrollEnable;
}

- (void)setPageControlHidden:(BOOL)pageControlHidden {
  
  _pageControlHidden = pageControlHidden;
  
  self.pageControl.hidden = pageControlHidden;
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
  
  _timeInterval = timeInterval;
  
  //todo:修改正在进行的timer的触发时间
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
  
  _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
  [self.pageControl setCurrentPageIndicatorTintColor:currentPageIndicatorTintColor];
  
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
  
  _pageIndicatorTintColor = pageIndicatorTintColor;
  [self.pageControl setPageIndicatorTintColor:pageIndicatorTintColor];
}

- (void)setAutoScroll:(BOOL)autoScroll {
  
  if (self.numberOfPages < 2) {
    
    autoScroll = NO;
  }
  _autoScroll = autoScroll;
  
  if (autoScroll) {
    
    [self start];
  } else {
    
    [self stop];
  }
}

- (void)setCurrentPage:(NSInteger)currentPage {

  _currentPage = currentPage;
  
  self.pageControl.currentPage = currentPage;
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(ACPageScrollView:didChangedPageControlToIndex:)]) {
    
    [self.delegate ACPageScrollView:self didChangedPageControlToIndex:currentPage];
  }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
  
  _numberOfPages = numberOfPages;
  
  self.pageControl.numberOfPages = numberOfPages;
  
  self.pageControl.hidden = (numberOfPages < 2);
 
  if (self.pageControlHidden == YES) {
    
    self.pageControl.hidden = YES;
  }
}

#pragma mark - Timer

- (void)start {
 
  if (self.numberOfPages < 2) return;
  if ([CYDispatchTimer isTimerExistWithName:self.timerName]) return;
 
  self.timerName = [CYDispatchTimer aNewTimerName];
  WeakSelf
  [CYDispatchTimer scheduledDispatchTimerInMainQueueWithName:self.timerName delay:self.timeInterval timeInterval:self.timeInterval repeats:YES action:^{
    
    [weakSelf timerEvent];
  }];
}

- (void)stop {
 
  [CYDispatchTimer cancelTimerWithName:self.timerName];
}

- (void)timerEvent {
  
  if (![CYDispatchTimer isTimerExistWithName:self.timerName]) return;
  if (self.collectionView.isDragging) return;
  
  NSIndexPath *currentIndexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];
  
  if ((currentIndexPath.row >= self.numberOfPages * 1900) && (currentIndexPath.row % self.numberOfPages == 0)) {
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.numberOfPages * 700 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
  }
  
  NSInteger nextItem = currentIndexPath.row + 1;
  NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:nextItem inSection:0];
 
  [self.collectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}


#pragma mark - collectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  return (self.numberOfPages == 1)? 1 : self.numberOfPages * 2000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  UICollectionViewCell *cell = [self.dataSource ACPageScrollView:self cellForPageAtIndex:indexPath.row % self.numberOfPages];
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(ACPageScrollView:willDisplayCellForItemAtIndex:)]) {
    
    [self.delegate ACPageScrollView:self willDisplayCellForItemAtIndex:indexPath.row % self.numberOfPages];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(ACPageScrollView:didDisplayCellForItemAtIndex:)]) {
    
    [self.delegate ACPageScrollView:self didDisplayCellForItemAtIndex:indexPath.row % self.numberOfPages];
  }
}

#pragma mark - collectionView layoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  return self.bounds.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  
  return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  
  return 0;
}


#pragma mark - collectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  [collectionView deselectItemAtIndexPath:indexPath animated:YES];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(ACPageScrollView:didSelectItemAtIndex:)]) {
    
    [self.delegate ACPageScrollView:self didSelectItemAtIndex:indexPath.row %[self numberOfPages]];
  }
}


#pragma mark - scrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  if (self.numberOfPages && scrollView.frame.size.width) {
    
    self.currentPage = (NSInteger)((scrollView.contentOffset.x + scrollView.frame.size.width / 2) / scrollView.frame.size.width) % self.numberOfPages;
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
  [self stop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
 
  if (self.autoScroll) {
    
    [self start];
  }
}

@end

 

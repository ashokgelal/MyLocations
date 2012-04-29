@interface HudView : UIView
+(HudView *)hudInView:(UIView *)view animated:(BOOL)animated;
@property (nonatomic, strong) NSString *text;
@end

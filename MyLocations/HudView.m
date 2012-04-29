#import "HudView.h"

@implementation HudView
@synthesize text;

+(HudView *)hudInView:(UIView *)view animated:(BOOL)animated
{
    HudView *hudView = [[HudView alloc]initWithFrame:view.bounds];
    hudView.opaque = NO;
    
    [view addSubview:hudView];
    view.userInteractionEnabled = NO;
   
    [hudView showAnimated:animated];
    return hudView;
}

-(void)showAnimated:(BOOL)animated
{
    if(animated){
        self.alpha = 0.0f;
        self.transform = CGAffineTransformMakeScale(1.3f, 1.3f);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        self.alpha = 1.0f;
        self.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    }
}

-(void)drawRect:(CGRect)rect
{
    const CGFloat boxWidth = 96.0f;
    const CGFloat boxHeight = 96.0f;
    
    CGRect boxRect = CGRectMake(roundf(self.bounds.size.width - boxWidth)/2.0f, roundf(self.bounds.size.height - boxHeight)/2.0f, boxWidth, boxHeight);
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:10.0f];
    [[UIColor colorWithWhite:0.0f alpha:0.75] setFill];
    [roundedRect fill];
    
    UIImage *image = [UIImage imageNamed:@"Checkmark"];
    CGPoint imagePoint = CGPointMake(self.center.x - roundf(image.size.width/2.0f), self.center.y - roundf(image.size.height / 2.0f) - boxHeight/8.0f);
    
    [image drawAtPoint:imagePoint];
    
    
    [[UIColor whiteColor]set];
    UIFont *font = [UIFont boldSystemFontOfSize:16.0f];
    CGSize textSize = [self.text sizeWithFont:font];
    CGPoint textPoint = CGPointMake(self.center.x - roundf(textSize.width / 2.0f), self.center.y - roundf(textSize.height / 2.0f)+boxHeight/4.0f);
    [self.text drawAtPoint:textPoint withFont:font];
}

@end
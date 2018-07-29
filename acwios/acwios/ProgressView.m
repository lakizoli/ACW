//
//  ProgressView.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "ProgressView.h"
IB_DESIGNABLE

@interface ProgressView ()

@property (nonatomic, weak) IBOutlet UILabel *progressLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIButton *button;

@end

@implementation ProgressView

-(id) init {
	self = [super init];
	if (self) {
		[self setup];
	}
	return self;
}

-(id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setup];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup {
	_cornerRadius = 0;
	_borderWidth = 0;
	_progressValue = 0;
}

#pragma mark - Properties

-(void) setCornerRadius:(float)cornerRadius {
    [[self layer] setCornerRadius:cornerRadius];
    [[self layer] setMasksToBounds:cornerRadius > 0];
}

-(void) setBorderWidth:(float)borderWidth {
    [[self layer] setBorderWidth:borderWidth];
}

-(void) setBorderColor:(UIColor *)borderColor {
    [[self layer] setBorderColor: borderColor.CGColor];
}

-(void) setProgressLabel:(UILabel *)progressLabel {
    _progressLabel = progressLabel;
    if (_labelContent) {
        [_progressLabel setText:_labelContent];
    }
}

-(void) setProgressView:(UIProgressView *)progressView {
	_progressView = progressView;
	[_progressView setProgress:_progressValue animated:YES];
}

-(void) setButton:(UIButton *)button {
    _button = button;
    if (_buttonLabel) {
        [_button setTitle:_buttonLabel forState:UIControlStateNormal];
    }
}

-(void) setLabelContent:(NSString *)labelContent {
    _labelContent = labelContent;
    if (_progressLabel) {
        [_progressLabel setText:labelContent];
    }
}

-(void) setButtonLabel:(NSString *)buttonLabel {
    _buttonLabel = buttonLabel;
    if (_button) {
        [_button setTitle:_buttonLabel forState:UIControlStateNormal];
    }
}

-(void) setProgressValue:(float)progressValue {
    _progressValue = progressValue;
    if (_progressView) {
        [_progressView setProgress:_progressValue animated:YES];
    }
}

#pragma mark - Event handlers

- (IBAction)buttonPressed:(id)sender {
	if (_onButtonPressed) {
		_onButtonPressed ();
	}
}


@end

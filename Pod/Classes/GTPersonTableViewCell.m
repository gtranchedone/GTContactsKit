//
//  GTPersonTableViewCell.m
//  GTContactsKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Gianluca Tranchedone (@gtranchedone)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GTPersonTableViewCell.h"

@implementation GTPersonTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const float verticalDistance = 5.0f;
    const float horizontalDistance = 15.0f;
    const float cellHeight = CGRectGetHeight(self.bounds);
    const float maxElementsHeight = (cellHeight - (verticalDistance * 2));

    self.imageView.clipsToBounds = YES;
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.frame = CGRectMake(horizontalDistance, verticalDistance, maxElementsHeight, maxElementsHeight);
    self.imageView.layer.cornerRadius = (CGRectGetHeight(self.imageView.bounds) / 2);

    if (![self.imageView isDescendantOfView:self.contentView]) {
        [self.contentView addSubview:self.imageView];
    }

    CGRect textFrame = self.textLabel.frame;
    
    textFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + horizontalDistance;
    textFrame.size.width = CGRectGetWidth(self.contentView.bounds) - textFrame.origin.x - horizontalDistance;
    
    CGRect textDetailFrame = self.detailTextLabel.frame;
    
    textDetailFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + horizontalDistance;
    textDetailFrame.size.width = CGRectGetWidth(self.contentView.bounds) - textFrame.origin.x - horizontalDistance;
    
    
    if (self.accessoryView) {
        textFrame.size.width -= (horizontalDistance + CGRectGetWidth(self.accessoryView.bounds));
        textDetailFrame.size.width -= (horizontalDistance + CGRectGetWidth(self.accessoryView.bounds));
    }
    
    self.textLabel.frame = textFrame;
    self.detailTextLabel.frame = textDetailFrame;

    self.separatorInset = UIEdgeInsetsMake(0, CGRectGetMinX(textFrame), 0, 0);
}

@end

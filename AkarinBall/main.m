//
//  main.m
//  AkarinBall
//
//  Created by あわあわ on 12/08/30.
//  Copyright (c) 2012年 pnlybubbles. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}

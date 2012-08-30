#
#  AppDelegate.rb
#  AkarinBall
#
#  Created by あわあわ on 12/08/30.
#  Copyright 2012年 pnlybubbles. All rights reserved.
#

require 'rubygems'
require 'net/https'
require 'oauth'
require 'cgi'
require 'json'
require 'openssl'
require 'date'

$consumer_key        = "0lEsPsea1jPXLAEN06pJGg"
$consumer_secret     = "cLyLDXCBuSk0S42YkQftLsLg51y8RPYcMSYZLX2s"
$access_token        = ""
$access_token_secret = ""

class AppDelegate
    attr_accessor :window
    attr_accessor :twitterAuthWindow
    attr_accessor :tweetField
    attr_accessor :tlView
    attr_accessor :textCount
    attr_accessor :oauthWebView
    attr_accessor :pinCodeField
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
    end
    
    def initialize
        @cnt = 0
        @tl_deta = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc)}
        
        unless File.exist?("AkarinBall.app/Contents/Preferences/oauth_key.plist")
            system("mkdir AkarinBall.app/Contents/Preferences")
            system("echo '' >> AkarinBall.app/Contents/Preferences/oauth_key.plist")
            output_file = File.open("AkarinBall.app/Contents/Preferences/oauth_key.plist", "w")
            output_deta = {'access_token'=>'＼ｱｯｶﾘ〜ﾝ／','access_token_secret'=>'＼ｱｯｶﾘ〜ﾝ／'}
            output_file.write(output_deta.to_plist)
            output_file.close
        end
        
        oauth_key_plist = NSString.stringWithContentsOfFile("AkarinBall.app/Contents/Preferences/oauth_key.plist",
                                                            encoding:NSUTF8StringEncoding,
                                                            error:nil)
        oauth_key = load_plist(oauth_key_plist)
        p oauth_key
        
        $access_token = oauth_key['access_token']
        $access_token_secret = oauth_key['access_token_secret']
        
        @consumer = OAuth::Consumer.new(
                                        $consumer_key,
                                        $consumer_secret,
                                        :site => 'http://twitter.com'
                                        )
        
        if($access_token != "＼ｱｯｶﾘ〜ﾝ／")
            @access_token = OAuth::AccessToken.new(
                                                   @consumer,
                                                   $access_token,
                                                   $access_token_secret
                                                   )
            getUserStream
            else
            alert = NSAlert.new
            alert.setMessageText("Welcome to AkarinBall!")
            alert.setInformativeText("\"AkarinBall > Account Authentication\" on status bar to Start.\n\nEnjoy!")
            alert.runModal()
        end
    end
    
    def getUserStream
        @stream_th = Thread.new do
            uri = URI.parse('https://userstream.twitter.com/2/user.json')
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl = true
            https.ca_file = './userstream.twitter.com.pem'
            https.verify_mode = OpenSSL::SSL::VERIFY_PEER
            https.verify_depth = 5
            https.start do |https|
                request = Net::HTTP::Get.new(uri.request_uri)
                request.oauth!(https, @consumer, @access_token)
                puts "streaming..."
                https.request(request) do |response|
                    response.read_body do |chunk|
                        buf = chunk
                        begin
                            json = JSON.parse(buf.strip)
                            if json['text'] then
                                user = json['user']
                                print user['screen_name'], ": ", json['text'], "\n"
                                @tl_deta[@cnt] = json
                                @cnt += 1
                                if(@cnt>=400)
                                    @tl_deta.delete(@cnt-400)
                                end
                                tlView.reloadData
                            end
                            rescue Exception => e
                            puts "#### #{e} ####"
                        end
                    end
                end
            end
        end
    end
    
    def numberOfRowsInTableView(aTableView)
        return @cnt
    end
    
    def tableView(aTableView, objectValueForTableColumn: aTableColumn, row: rowIndex)
        case aTableColumn.identifier
            when 'image'
            nsurl = NSURL.URLWithString(@tl_deta[@cnt-rowIndex-1]['user']['profile_image_url'].gsub(/_normal/,""))
            imgdeta = NSImage.alloc.initWithContentsOfURL(nsurl)
            imgdeta.setSize(NSSize.NSMakeSize(55, 55))
            return imgdeta
            return
            when 'screen_name'
            return @tl_deta[@cnt-rowIndex-1]['user']['screen_name']
            when 'text'
            return @tl_deta[@cnt-rowIndex-1]['text'].gsub(/\n/,"")
            when 'created_at'
            crtat = DateTime.strptime(@tl_deta[@cnt-rowIndex-1]['created_at'],"%a %b %d %H:%M:%S %Z %Y").new_offset(Rational(9,24))
            return crtat.strftime('%H:%M:%S')
        end
    end
    
    def tweet(sender)
        textcnt = tweetField.stringValue.split(//).size.to_i
        textCount.stringValue = 140-textcnt
        if(textcnt<=140)
            posttext = tweetField.stringValue
            if(posttext!="")
                if(@reply_to==nil)
                    @access_token.post('/statuses/update.json','status' => "#{posttext}")
                    else
                    @access_token.post('/statuses/update.json','status' => "#{posttext}",
                                       'in_reply_to_status_id' => @reply_to)
                    @reply_to = nil
                end
                tweetField.stringValue = ""
                textCount.stringValue = "140"
            end
        end
    end
    
    def reply(sender)
        tweetField.stringValue = "@" + @tl_deta[@cnt-tlView.selectedRow-1]['user']['screen_name'] + " "
        @reply_to = @tl_deta[@cnt-tlView.selectedRow-1]['id']
    end
    
    def replyWith(sender)
        tweetField.stringValue = "RT @" + @tl_deta[@cnt-tlView.selectedRow-1]['user']['screen_name'] + ": " + @tl_deta[@cnt-tlView.selectedRow-1]['text']
        @reply_to = @tl_deta[@cnt-tlView.selectedRow-1]['id']
    end
    
    def retweet(sender)
        id = @tl_deta[@cnt-tlView.selectedRow-1]['id']
        @access_token.post("/statuses/retweet/#{id}.json")
    end
    
    def favorite(sender)
        id = @tl_deta[@cnt-tlView.selectedRow-1]['id']
        @access_token.post("/favorites/create/#{id}.json")
    end
    
    def pakuri(sender)
        posttext = @tl_deta[@cnt-tlView.selectedRow-1]['text']
        @access_token.post('/statuses/update.json','status' => "#{posttext}")
    end
    
    def favrt(sender)
        id = @tl_deta[@cnt-tlView.selectedRow-1]['id']
        @access_token.post("/favorites/create/#{id}.json")
        @access_token.post("/statuses/retweet/#{id}.json")
    end
    
    def favpaku(sender)
        id = @tl_deta[@cnt-tlView.selectedRow-1]['id']
        posttext = @tl_deta[@cnt-tlView.selectedRow-1]['text']
        @access_token.post("/favorites/create/#{id}.json")
        @access_token.post('/statuses/update.json','status' => "#{posttext}")
    end
    
    def favrtpaku(sender)
        id = @tl_deta[@cnt-tlView.selectedRow-1]['id']
        posttext = @tl_deta[@cnt-tlView.selectedRow-1]['text']
        @access_token.post("/favorites/create/#{id}.json")
        @access_token.post("/statuses/retweet/#{id}.json")
        @access_token.post('/statuses/update.json','status' => "#{posttext}")
    end
    
    def ahya(sender)
        spase = ""
        0.upto(@ahya_cnt) do
            spase += "　"
        end
        @access_token.post('/statuses/update.json','status' => "ﾍ(ﾟ∀ﾟﾍ)ｱﾋｬ#{spase}")
        @ahya_cnt += 1
        if(@ahya_cnt >= 20)
            @ahya_cnt = 0
        end
    end
    
    def reconnectStream(sender)
        initialize
    end
    
    def oauthTwitterReq(sender)
        oauthTwitter
    end
    
    def oauthTwitter
        twitterAuthWindow.makeKeyAndOrderFront(twitterAuthWindow)
        @request_token = @consumer.get_request_token
        puts "Access this URL and approve => #{@request_token.authorize_url}"
        url = @request_token.authorize_url
        nsurl = NSURL.URLWithString(url)
        nsurl_req = NSURLRequest.requestWithURL(nsurl)
        oauthWebView.mainFrame.loadRequest(nsurl_req)
    end
    
    def authPinCode(sender)
        oauth_verifier = pinCodeField.stringValue
        access_token = @request_token.get_access_token(
                                                       :oauth_verifier => oauth_verifier
                                                       )
        puts "Access token: #{access_token.token}"
        puts "Access token secret: #{access_token.secret}"
        rel = false
        if($access_token != "＼ｱｯｶﾘ〜ﾝ／")
            rel = true
        end
        $access_token        = access_token.token
        $access_token_secret = access_token.secret
        output_deta = {'access_token'=>$access_token,'access_token_secret'=>$access_token_secret}
        output_file = File.open("AkarinBall.app/Contents/Preferences/oauth_key.plist", "w")
        output_file.write(output_deta.to_plist)
        output_file.close
        twitterAuthWindow.close
        if(rel)
            alert = NSAlert.new
            alert.setMessageText("Loading success!!")
            alert.setInformativeText("Relaunch to Reset UserStream.")
            alert.addButtonWithTitle("Relaunch")
            alert.runModal()
            relaunch
            else
            initialize
        end
    end
    
    def relaunch
        system("sh -c 'sleep 1; open -b com.pnlybubbles.AkarinBall'");
        exit(0)
    end
    
    def showMainWindow(sender)
        window.makeKeyAndOrderFront(window)
    end
end

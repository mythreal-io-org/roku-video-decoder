'2020.01 play video with sdk1 and SG. both playlist and single video. with or without eventloop
#const SCENE_GRAPH = true 'false means sdk1, and is good  'roVideoPlayer SDK1 vs SDK2
#const PLAYLIST = true ' true not working
#const LOOP_SDK1 = false 'need this to be true to exit when finished playing, Back button not working regardless
Function Main() as void
#if SCENE_GRAPH
	version = "SG"
#else
	version = "SDK1"
#end if
    print "roVideoPlayer playlist demo Main entered: "version
#if SCENE_GRAPH
    screen = CreateObject("roSGScreen")
    scene = screen.CreateScene("Scene")
    screen.show()
	init(scene)
	scene.setFocus(true)

#else
    port = CreateObject("roMessagePort")
    screen = CreateObject("roScreen", true)
#if LOOP_SDK1
    screen.setMessagePort(port)
    screen.clear(&h00)
    screen.swapBuffers()
    screen.clear(&h00)
    screen.swapBuffers()
#else
    screen.clear(&h00) 'both clear and  screen.swapBuffers required, otherwise just black. don't know why
    screen.swapBuffers()
#end if

   video = CreateObject("roVideoPlayer")
   video.setMessagePort(port)
   video.setPositionNotificationPeriod(1)
   video.setContentList([
            {
                Stream: { url: "pkg:/images/video.mp4" }
                StreamFormat: "mp4"
                'PlayDuration: 10
            },
            ' {
            '     Stream: { url: "pkg:/images/video2.mp4" }
            '     StreamFormat: "mp4"
            '     'PlayDuration: 10
            ' } ' StreamFormat "ism" also good.
    ])

   video.SetLoop(true)
   video.PreBuffer()

   video.Play()
#end if
    contentPos = 0
    playerPos = 0

	print "starting eventloop"
    while (true)
#if SCENE_GRAPH
#else
	#if LOOP_SDK1
		if LoopSdk1(port) = 1
			print "Sdk1 exiting eventloop"
			exit while
		end if
	#end if
#end if
    end while
	print "Sdk1 done eventloop"
End Function

#if SCENE_GRAPH
	Function init(scene) as void
		print "init entered"
		if scene = Invalid
			print "invalid scene"
			return
		end if
		video = CreateObject("roSGNode", "Video")

        video.loop = true
        video.enableScreenSaverWhilePlaying = false
        video.disableScreenSaver = true

		video.reparent(scene, false)
		content = createObject("RoSGNode", "ContentNode")
	#if PLAYLIST
		video.contentIsPlaylist = true
		
        child = content.createChild("ContentNode")
		child.setFields({
            streamFormat:"mp4",
            URL:"pkg:/images/video.mp4",
            'URL:"https://vod.grupouninter.com.br/2017/DEZ/201703381-A01.mp4"
            'URL: "pkg:/images/Top_10_games_1minute.mov",
            'URL: "http://localhost/Images/Top_10_games_1minute.mov"
            VideoDisableUI: true,
            IgnoreStreamErrors: true,
            FullHD: true
        })
        'child.setFields({streamFormat:"hls", URL:"https://roku.s.cpl.delvenetworks.com/media/59021fabe3b645968e382ac726cd6c7b/60b4a471ffb74809beb2f7d5a15b3193/roku_ep_111_segment_1_final-cc_mix_033015-a7ec8a288c4bcec001c118181c668de321108861.m3u8"})
		
        'child = content.createChild("ContentNode")
		'child.setFields({streamFormat:"mp4", URL:"pkg:/images/video2.mp4"})
		
        content.nextContentIndex = 0
		contentType = "playlist"
	#else
		content.setFields({streamFormat:"mp4", URL:"pkg:/images/video.mp4"})
		contentType = "singlecontent"
	#end if
		video.content = content
		video.control = "play"
		if video <> Invalid
			video.setFocus(true)
		end if
		' video.trickPlayBackground exists
		print "init exiting with "contentType
		
	End Function
#else
	Function LoopSdk1(port) as Integer
        msg = wait(0, port)
        if type(msg) = "roVideoPlayerEvent"
            status = msg.GetMessage()
            if msg.isFullResult()
                print "LoopSdk1 will cause exit loop. status= "status
                return 1 'hit here when playlist finished playing
            else if msg.isStatusMessage()
                if status <> "startup progress" 'a few times, only at the begging of the playlist
                    print "isStatusMessage, status= "status;  " contentPos="contentPos
					'[status= end of stream] when going to next content inside the playlist
					'[status= start of play] only at the begging of the playlist, after last "startup progress"
                end if
                if status = "playback stopped"
                    contentPos = contentPos + 1
                end if
            else if msg.isPlaybackPosition()
                print "player pos "; msg.GetIndex(); " seconds"
            end if
        end if
		return 0
	End Function
#end if

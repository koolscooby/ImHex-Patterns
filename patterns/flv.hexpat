#pragma description FLV media file

#pragma endian big
#pragma pattern_limit 500000
#pragma MIME video/x-flv

// Documentation References:
//
// Veovera Software Organization Enhanced RTMP Specification v2:
//    https://veovera.org/docs/enhanced/enhanced-rtmp-v2
// Adobe/Veriskope Video File Format Version 10:
//    https://rtmp.veriskope.com/pdf/video_file_format_spec_v10.pdf

import std.mem;

bitfield FlvHeaderTypeFlags {
    padding : 5;
    bool audio : 1;
    padding : 1;
    bool video : 1;
};

struct FlvHeader {
    char signature[3];
    u8 version;
    FlvHeaderTypeFlags typeFlags;
    u32 dataOffset;
    u32 alwaysZero;
};

enum FlvTagType : u8 {
    Audio = 8,
    Video = 9,
    Script = 18
};

enum SoundFormat : u8 {
    LPcmPlatformEndian = 0,
    AdPcm = 1,
    Mp3 = 2,
    LPcmLittleEndian = 3,
    Nellymoser16KMono = 4,
    Nellymoser8KMono = 5,
    Nellymoser = 6,
    G711ALaw = 7,
    G711MuLaw = 8,
    ExHeader = 9,
    Aac = 10,
    Speex = 11,
    Mp3_8K = 14,
    Native = 15
};

enum SoundRate : u8 {
    KHz_5_5 = 0,
    KHz_11 = 1,
    KHz_22 = 2,
    KHz_44 = 3,
};

enum SoundSize : bool {
    snd8Bit = 0,
    snd16Bit = 1,
};

enum SoundType : bool {
    sndMono = 0,
    sndStereo = 1,
};

enum AudioPacketType : u8 {
    SequenceStart = 0,
    CodedFrames = 1,
    SequenceEnd = 2,
    MultichannelConfig = 4,
    Multitrack = 5,
    ModEx = 7,
};

enum AvMultitrackType : u8 {
    OneTrack = 0,
    ManyTracks = 1,
    ManyTracksManyCodecs = 2,
};

enum AudioFourCc : u32 {
    Ac3 = 0x61632d33,  //"ac-3"
    Eac3 = 0x65632d33, //"ec-3"
    Opus = 0x4f707573, //"Opus"
    Mp3 = 0x2e4d7033,  //".Mp3"
    Flac = 0x664c6143, //"fLaC"
    Aac = 0x6d703461,  //"mp4a"
    
};

bitfield ExAudioTagHeader {
    SoundFormat soundFormat : 4;
    if (soundFormat != SoundFormat::ExHeader){
        SoundRate soundRate : 2;
        SoundSize soundSize : 1;
        SoundType soundType : 1;
    } else if(soundFormat == SoundFormat::ExHeader){
        AudioPacketType audioPacketType;
        // TODO: while (audioPacketType == AudioPacketType.ModEx) { }
        if (audioPacketType == AudioPacketType::Multitrack){
            AvMultitrackType audioMultitrackType;
            if (audioMultitrackType != AvMultitrackType::ManyTracksManyCodecs) {
                AudioFourCc audioFourCC;
            }
        } else {
            AudioFourCc audioFourCC;
        }
    }
};

struct AudioTagHeader {
    ExAudioTagHeader exAudioTagHeader [[inline]];
};

enum VideoFrameType : u8 {
    KeyFrame = 1,
    InterFrame = 2,
    DisposableInterFrame = 3,
    GeneratedKeyFrame = 4,
    Command = 5,
};

enum VideoCodecID : u8 {
    Sorensen_H263 = 2,
    Screen = 3,
    On2VP6 = 4,
    On2VP6A = 5,
    ScreenV2 = 6,
    Avc = 7,
};

enum AVCPacketType : u8 {
    AVC_SequenceHeader = 0,
    AVC_NALU = 1,
    AVC_EndOfSequence = 2,
};

enum VideoPacketType : u8 {
    SequenceStart = 0,
    CodedFrames = 1,
    SequenceEnd = 2,
    CodedFramesX = 3,
    Metadata = 4,
    MPEG2TSSequenceStart = 5,
    Multitrack = 6, 
    ModEx = 7,
};

enum VideoCommand : u8 {
    StartSeek = 0,
    EndSeek = 1,
};

bitfield VideoMultitrackTypes {
    AvMultitrackType avMultitrackType :4;
    VideoPacketType videoPacketType: 4;
};

enum VideoFourCc : u32 {
    Vp8 = 0x76703038,  //"vp08"
    Vp9 = 0x76703039,  //"vp09"
    Av1 = 0x61763031,  //"av01"
    Avc = 0x61766331,  //"avc1"
    Hevc = 0x68766331, //"hvc1"
};

bitfield ExVideoTagHeader {
    bool isExVideoHeader : 1;
    VideoFrameType videoFrameType : 3;
    if (isExVideoHeader == 0){
        VideoCodecID videoCodecId : 4;
    } else {
        VideoPacketType videoPacketType :4;
        // TODO: while (videoPacketType == VideoPacketType.ModEx) { }
        if (videoPacketType != VideoPacketType::Metadata &&
            videoFrameType == VideoFrameType::Command ){
            VideoCommand videoCommand;    
        } else if (videoPacketType == VideoPacketType::Multitrack) {
            VideoMultitrackTypes videoMultitrackTypes;
            if (videoMultitrackTypes.avMultitrackType != AvMultitrackType::ManyTracksManyCodecs){
                VideoFourCc videoFourCC;
            }
        } else {
            VideoFourCc videoFourCC;
        }
    }
};

struct VideoTagHeader {
    ExVideoTagHeader exVideoTagHeader [[inline]];
    if (exVideoTagHeader.isExVideoHeader == 0){
        if (exVideoTagHeader.videoFrameType == VideoFrameType::Command){
            VideoCommand videoCommand;
        }
        if (exVideoTagHeader.videoCodecId == VideoCodecID::Avc) {
            AVCPacketType avcPacketType;
            s24 CompositionTime;
        }
    }
};

struct FlvTag {
    FlvTagType tagType;
    u24 dataSize;
    u24 timeStamp;
    u8 timeStampExtended;
    u24 streamId;
    
    if(tagType == FlvTagType::Audio){
        AudioTagHeader audioTagHeader;
        // AudioTagBody:
        $ += dataSize - sizeof(audioTagHeader);
    } else if(tagType == FlvTagType::Video){
        VideoTagHeader videoTagHeader;
        // VideoTagBody:
        $ += dataSize - sizeof(videoTagHeader);
    // TODO: } else if(tagType == FlvTagType::Script){
    } else {
        $ += dataSize;
    }
    u32 previousTagSize;
};

struct Flv {
    FlvHeader flvHeader [[inline]];
    FlvTag tags[while(!std::mem::eof())] [[inline]];
};

Flv flv @ 0x00;
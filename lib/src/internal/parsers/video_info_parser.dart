import 'adaptive_stream_info_parser.dart';
import 'muxed_stream_info_parser.dart';
import 'dart:convert';

class VideoInfoParser {
  Map<String, String> _root;
  bool isLive;

  VideoInfoParser(this._root);

  String parseStatus() => _root['status'];

  // String parseId() => _root["video_id"]; // no longer provided
  int parseErrorCode() => _root['errorcode'] == null ? 0 : int.tryParse(_root['errorcode']);

  String parseErrorReason() => _root["reason"];

  String parsePreviewVideoId() => _root['ypc_vid'];

  String parseDashManifestUrl() => jsonDecode(_root['player_response'])['streamingData']['dashManifestUrl'];

  String parseHlsPlaylistUrl() => jsonDecode(_root['player_response'])['streamingData']['hlsManifestUrl'];

  List<MuxedStreamInfoParser> getMuxedStreamInfo() {
    var streamInfosEncoded = _root['url_encoded_fmt_stream_map'];
    // List that we will full
    var builtList = List<MuxedStreamInfoParser>();
    if (streamInfosEncoded == null) {
      var playerResponse = jsonDecode(_root['player_response']);
      var format = playerResponse['streamingData']['formats'][0];
      var itag = format['itag'];
      var quality = format['quality'];
      var type = format['mimeType'];
      var cipher = format['cipher'];
      Map<String, String> map = Uri.splitQueryString(cipher);
      map["itag"] = itag.toString();
      map["quality"] = quality;
      map["type"] = type;
      builtList.add(MuxedStreamInfoParser(map));
      return builtList;
    }
    // Extract the streams and return a list
    var streams = streamInfosEncoded.split(',');
    streams.forEach((stream) {
      builtList.add(MuxedStreamInfoParser(Uri.splitQueryString(stream)));
    });
    return builtList;
  }

  List<AdaptiveStreamInfoParser> getAdaptiveStreamInfo() {
    var streamInfosEncoded = _root['adaptive_fmts'];
    if (streamInfosEncoded == null) {
      return List<AdaptiveStreamInfoParser>();
    }
    // List that we will full
    var builtList = List<AdaptiveStreamInfoParser>();
    // Extract the streams and return a list
    var streams = streamInfosEncoded.split(',');
    streams.forEach((stream) {
      builtList.add(AdaptiveStreamInfoParser(Uri.splitQueryString(stream)));
    });
    return builtList;
  }

  static VideoInfoParser initialize(String raw) {
    var root = Uri.splitQueryString(raw);
    return VideoInfoParser(root);
  }
}

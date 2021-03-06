%%%-------------------------------------------------------------------
%%% @author karl l <karl@ninjacontrol.com>
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(m3u8_playlist).

-export([generate/1]).

-include("include/m3u8.hrl").

-define(EOL,"\n").


generate(Items) ->
    generate(Items,[]).

generate([ I = #header{} |T],Acc)->
    generate(T,[ [m3u8:header(), ?EOL] |Acc]);

generate([I = #segment_duration{} |T],Acc) ->

    case I#segment_duration.title of
	undefined ->
	    generate(T,[ [m3u8:segment_duration(I#segment_duration.duration),?EOL] |Acc]);
	_ ->
	    generate(T,[ [m3u8:segment_duration(I#segment_duration.duration,
						I#segment_duration.title),?EOL] |Acc])
    end;

generate([I = #media{} | T], Acc) ->
    generate(T, [ [m3u8:media(media_attrs(I)), ?EOL] | Acc ]);
		 
generate([I = #stream{} | T], Acc) ->
    generate(T, [ [m3u8:stream(stream_attrs(I), I#stream.uri), ?EOL] | Acc ]);

generate([I = #i_frame_stream{} | T], Acc) ->
    generate(T, [ [m3u8:i_frame_stream(i_frame_stream_attrs(I)), ?EOL] | Acc ]);

generate([ I = #program_date_time{} |T],Acc)->

    Year = I#program_date_time.year,
    Month = I#program_date_time.month,
    Day = I#program_date_time.day,
    Hour = I#program_date_time.hour,
    Minute = I#program_date_time.minute,
    Second = I#program_date_time.second,
    Offset = [ tz_attrs( I#program_date_time.utc, 
			 I#program_date_time.offset_sign,
			 I#program_date_time.offset_hour,
			 I#program_date_time.offset_minute ) ],

    generate(T, [ [m3u8:program_date_time( Year, Month, Day, Hour, Minute, Second, Offset ), ?EOL] | Acc]);

generate([ I = #program_date_time_now{} |T],Acc)->
    generate(T, [ [m3u8:program_date_time(), ?EOL] | Acc]);

generate([I = #discontinuity{} | T], Acc) ->
    generate(T, [ [m3u8:discontinuity(), ?EOL] | Acc ]);

generate([I = #i_frames_only{} | T], Acc) ->
    generate(T, [ [m3u8:i_frames_only(), ?EOL] | Acc ]);

generate([I = #version{} | T], Acc) ->
    generate(T, [ [m3u8:version(I#version.version), ?EOL] | Acc ]);

generate([I = #endlist{} | T], Acc) ->
    generate(T, [ [m3u8:endlist(), ?EOL] | Acc ]);

generate([I = #cache{} | T], Acc) ->
    generate(T, [ [m3u8:allow_cache(I#cache.allow), ?EOL] | Acc ]);

generate([I = #playlist_type{} | T], Acc) ->
    generate(T, [ [m3u8:playlist_type(I#playlist_type.type), ?EOL] | Acc ]);


generate([I = #segment_key{} | T], Acc) ->
    generate(T, [ [m3u8:segment_key(segment_key_attrs(I)), ?EOL] | Acc ]);

generate([I = #media_sequence{} | T], Acc) ->
    generate(T, [ [m3u8:media_sequence(I#media_sequence.number), ?EOL] | Acc ]);

generate([I = #max_segment_duration{} | T], Acc) ->
    generate(T, [ [m3u8:max_segment_duration(I#max_segment_duration.seconds), ?EOL] | Acc ]);

generate([I = #segment_subrange{} | T], Acc) ->

    case I#segment_subrange.offset of
	undefined ->
	    generate(T,[ [m3u8:segment_subrange(I#segment_subrange.length),?EOL] |Acc]);
	_ ->
	    generate(T,[ [m3u8:segment_subrange(I#segment_subrange.length,
						I#segment_subrange.offset),?EOL] |Acc])
    end;


generate([], Acc) ->
    lists:flatten(lists:reverse(Acc)).

media_attrs( I = #media{} ) ->
    
    Attrs = [ kv(uri,I#media.uri),
	      map_flag(I#media.type,[{audio,type_audio},{video,type_video}]),
	      kv(group_id,I#media.group_id),
	      kv(language,I#media.language),
	      kv(name,I#media.name),
	      map_flag(I#media.default,[{yes,default},{no,not_default}]),
	      map_flag(I#media.autoselect,[{yes,autoselect},{no,no_autoselect}]) ],
    lists:flatten(Attrs).

stream_attrs( I = #stream{} ) ->
    
    Attrs = [ kv(bandwidth,I#stream.bandwidth),
	      kv(program_id,I#stream.program_id),
	      kv(codecs,I#stream.codecs),
	      kv(resolution,I#stream.resolution),
	      kv(audio,I#stream.audio),
	      kv(video,I#stream.video) ],
	      
    lists:flatten(Attrs).

i_frame_stream_attrs( I = #i_frame_stream{} ) ->
    
    Attrs = [ kv(uri,I#i_frame_stream.uri),
	      kv(bandwidth,I#i_frame_stream.bandwidth),
	      kv(program_id,I#i_frame_stream.program_id),
	      kv(video,I#i_frame_stream.video),
	      kv(codecs,I#i_frame_stream.codecs),
	      kv(resolution,I#i_frame_stream.resolution)  ],
	      
    lists:flatten(Attrs).

segment_key_attrs( I = #segment_key{} ) ->
    
    Attrs = [ 
	      map_key(uri, I#segment_key.uri,[{uri,key_uri}]),
	      map_flag(I#segment_key.method,[{none,method_none},{aes128,method_aes128}])
	    ],
	      
    lists:flatten(Attrs).


tz_attrs(Utc, Offset_sign, Offset_hour, Offset_minute) ->
    case Utc of
	undefined ->
	    case Offset_minute of
		undefined ->
		    {Offset_sign, Offset_hour};
		_ ->
		    {Offset_sign, Offset_hour, Offset_minute}
	    end;
	_ -> utc
    end.
	      	      


%
% Handle undefined fields in the record, and mappings of values and keys 
%

map_key(_,undefined,_) ->
    [];
map_key(Name,Value,NameMap) when is_list(NameMap) ->
    case length(NameMap) of
	0 -> {Name,Value};
	_ -> MappedName = proplists:get_value(Name,NameMap),
	     {MappedName,Value}
    end.

map_flag(undefined,_) ->
    [];
map_flag(Value,ValueMap) ->
    MappedFlag = proplists:get_value(Value,ValueMap),
    MappedFlag.


kv (Name,undefined) ->
    [];
kv (Name,Value) ->
    {Name,Value}.


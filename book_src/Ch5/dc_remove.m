function dc_out=dc_remove(dc_in)
  dc_all=sum(dc_in);
  dc_offset=dc_all/length(dc_in);
  dc_out=dc_in-dc_offset;
end
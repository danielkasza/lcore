/* Calculate condition codes. */
function [2:0] cc_calc(input [15:0] value);
begin
    reg n = value[15];
    reg z = value == 0;
    reg p = !n && !z;
    cc_calc = {n,z,p};
end
endfunction

/* Module wrapper for above function. */
module Cc(
    input [15:0] value,
    output [2:0] cc
);

assign cc = cc_calc(value);

endmodule

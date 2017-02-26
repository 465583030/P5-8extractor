//	Module name: parser
//	Authority @ lijunnan
//	Last edited time: 2017/02/13
//	Function outline: programmable parser
//
`timescale 1ns/1ns
module parser(
clk,
reset,
headerData_valid,	// pktHead_valid
headerData,			// 138bit, wider width will be considered later
headerData_finish_valid,	// the valid time is set at the end of pktHead
pktID,
headerVector_valid,	// resultAccumulator
headerVector,		//
ruleSet_valid,		// TCAM and Action RAM, maybe fieldLocation_RAM
ruleSet,
result_valid,
result,
bid_bitmap
);
parameter	numExtraction =8,
			widthExtraction=3,
			limitTime	= 50000,
			widthPkt	= 138,
			widthHeaderData	= 32,
			widthHeaderVector	= 200,	// 8bit pktID, 192bit metadata;
			depthTCAM	= 6;


input	clk;
input	reset;
input	[numExtraction-1:0]	headerData_valid;
input	[widthHeaderData*numExtraction-1:0]	headerData;
input	[numExtraction-1:0]	headerData_finish_valid;
input	[8*numExtraction-1:0] pktID;
output	wire	headerVector_valid;
output	wire	[widthHeaderVector-1:0]	headerVector;
input	ruleSet_valid;//input
input	[169:0]	ruleSet;//input Next state; typeLocation; HeadVectorLocation; fieldLocation; ruleNum
						//[169:168]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
						//[167:128] key:type+state ;
						//[117:120]: nextState;	[119:104]:typeLocation,+ 8bit typeMask;	[103:8]fieldLocations;	[7:0]ruleNum
output	wire	result_valid;
output	wire	[119:0]	result;
output	wire	[numExtraction-1:0]	bid_bitmap;

//register temp//
integer n;


//=============wire between modules=============//
//distributor with others



//identifier with others
wire	[44:0]	type_out;
wire	type_out_valid;	

//TCAM with others
wire	indexTCAM_valid;
wire	[depthTCAM+4:0] indexTCAM;
wire	resultTCAM_valid;
wire	[63:0]	resultTCAM;

//ruleSet
wire	ruleSetTCAM_valid;
wire	[49:0] 	ruleSetTCAM;	// [49:48] operationCode 2'd0:read; 2'd1:add; 2'd2:del;
								// 	[47:8] key:type+state;
								//	[7:0] ruleNUM;
wire	ruleSetActionRAM_valid;
wire	[129:0] 	ruleSetActionRAM;	// 	[129:128]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
										//	[127:120]: nextState;	[119:112]:typeLocation; [111:104] typeMask;
										//	[103:8]fieldLocations;	
										//	[7:0]ruleNum

//ActionRAM with others
wire	action_valid;
wire	[124:0]	action;	//[124:120] bid; [119:96] state + typeOffset + 8bit mask(num); [95:0]: filedLocation;
//wire	resultActionRAM_valid;
//wire	[111:0] resultActionRAM;

//fieldExtractor with others
wire	stateType_valid[numExtraction-1:0];
wire	[44:0]	stateType[numExtraction-1:0];
wire	field_valid[numExtraction-1:0];
wire	[31:0]	field[numExtraction-1:0];
wire	field_finish_valid[numExtraction-1:0];
wire	[23:0]	field_finish_bid[numExtraction-1:0];	// 8bit action; 3bit reserved; 5bit bid + 8bit pktID;
wire	[11:0]	hvOffset[numExtraction-1:0];	// 5bit:ramID+ 7bit offset;

//result_accumulator with others
wire	metadata_valid[numExtraction-1:0];
wire	[widthHeaderVector-1:0] metadata[numExtraction-1:0];

//result_mux with others

// assign

 	
/*
distributor distributor(
.clk(clk),
.reset(reset),
.headerData_in_valid(headerData_valid),
.headerData_in(headerData),
.headerEnd_valid(headerEnd_valid),
.bid_bitmap(bid_bitmap),
.headerData_out_valid(headerData_out_valid),
.headerData_out(headerData_out),
.pktID_out(pktID),
.headerData_finish_valid(headerData_finish_valid),
.headerIn_enable(headerIn_enable)
);
defparam 	distributor.widthHeaderData = widthHeaderData,
			distributor.numExtraction = numExtraction,
			distributor.widthPkt = widthPkt;
*/
identifier identifier(
.clk(clk),
.reset(reset),
.stateType_valid_0(stateType_valid[0]),
.stateType_0(stateType[0]),
.stateType_valid_1(stateType_valid[1]),
.stateType_1(stateType[1]),
.stateType_valid_2(stateType_valid[2]),
.stateType_2(stateType[2]),
.stateType_valid_3(stateType_valid[3]),
.stateType_3(stateType[3]),
.stateType_valid_4(stateType_valid[4]),
.stateType_4(stateType[4]),
.stateType_valid_5(stateType_valid[5]),
.stateType_5(stateType[5]),
.stateType_valid_6(stateType_valid[6]),
.stateType_6(stateType[6]),
.stateType_valid_7(stateType_valid[7]),
.stateType_7(stateType[7]),
.type_out(type_out),
.type_out_valid(type_out_valid)
);
defparam 	identifier.numExtraction = numExtraction,
			identifier.widthExtraction = widthExtraction,
			identifier.widthHeaderData = widthHeaderData;			
			
BVbasedSearcher TCAM(
.clk(clk),
.reset(reset),
.key(type_out),
.key_valid(type_out_valid),
.index_valid(indexTCAM_valid),
.index(indexTCAM),
.ruleSet_valid(ruleSetTCAM_valid),
.ruleSet(ruleSetTCAM),
.result_valid(resultTCAM_valid),
.result(resultTCAM)
);
defparam	TCAM.depthTCAM = depthTCAM;

actionRAM actionRAM(
.clk(clk),
.reset(reset),
.index_valid(indexTCAM_valid),
.index(indexTCAM),
.action_valid(action_valid),
.action(action),
.ruleSet_valid(ruleSetActionRAM_valid),
.ruleSet(ruleSetActionRAM),
.result_valid(result_valid),
.result(result)
);
defparam	actionRAM.depthRAM = depthTCAM;


generate
	genvar i;
	for(i=0;i<numExtraction;i=i+1) begin : extractor
		extractor fieldExtractor(
		.clk(clk),
		.reset(reset),
		.headerData_valid(headerData_valid[i]),
		.headerData(headerData[i*32+31:i*32]),
		.headerData_finish_valid(headerData_finish_valid[i]),
		.pktID(pktID[i*8+7:i*8]),
		.action_valid(action_valid),
		.action(action),
		.field_valid(field_valid[i]),
		.field(field[i]),
		.hvOffset(hvOffset[i]),
		.field_finish_valid(field_finish_valid[i]),
		.field_finish_bid(field_finish_bid[i]),
		.bid_enable(bid_bitmap[i]),
		.stateType_valid(stateType_valid[i]),
		.stateType(stateType[i])
		);
		defparam 	fieldExtractor.extractionID = i,
					fieldExtractor.widthExtraction = widthExtraction,
					fieldExtractor.widthHeaderData = widthHeaderData;
	end
endgenerate	


generate
	genvar j;
	for(j=0;j<numExtraction;j=j+1) begin : result_accumulator
		result_accumulator result(
		.clk(clk),
		.reset(reset),
		.field_valid(field_valid[j]),
		.field(field[j]),
		.offset(hvOffset[j]),
		.field_finish_valid(field_finish_valid[j]),
		.field_finish_bid(field_finish_bid[j]),
		.metadata_valid(metadata_valid[j]),
		.metadata(metadata[j])
		);
		defparam 	result.widthHeaderData = widthHeaderData,
					result.widthHeaderVector=widthHeaderVector;
	end
endgenerate

result_mux result_mux(
.clk(clk),
.reset(reset),
.metadata_valid_0(metadata_valid[0]),
.metadata_0(metadata[0]),
.metadata_valid_1(metadata_valid[1]),
.metadata_1(metadata[1]),
.metadata_valid_2(metadata_valid[2]),
.metadata_2(metadata[2]),
.metadata_valid_3(metadata_valid[3]),
.metadata_3(metadata[3]),
.metadata_valid_4(metadata_valid[4]),
.metadata_4(metadata[4]),
.metadata_valid_5(metadata_valid[5]),
.metadata_5(metadata[5]),
.metadata_valid_6(metadata_valid[6]),
.metadata_6(metadata[6]),
.metadata_valid_7(metadata_valid[7]),
.metadata_7(metadata[7]),
.headerVector_valid(headerVector_valid),
.headerVector(headerVector)
);
defparam 	result_mux.widthHV = widthHeaderVector,
			result_mux.widthHeaderData = widthHeaderData;


ruleConfigurer ruleConfigurer(
.clk(clk),
.reset(reset),
.ruleSet_valid(ruleSet_valid),
.ruleSet(ruleSet),
.ruleSetTCAM_valid(ruleSetTCAM_valid),
.ruleSetTCAM(ruleSetTCAM),
.ruleSetActionRAM_valid(ruleSetActionRAM_valid),
.ruleSetActionRAM(ruleSetActionRAM)
);




endmodule

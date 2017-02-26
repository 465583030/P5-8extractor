P5: Programmable Parsers with Packet-level Parallel Processing
================================================================

**Platform introduction:
We implement P5 on NetMagic, an Altera FPGA integrated platform.
NetMagic contains 8×1Gbps Ethernet ports without 10 Gbps Ethernet 
port, the detail description can be seen at http://www.netmagic.org.
If you are interested in the development of NetMaigc to design your
SDN switches, you can join us to open-source project named FAST 
together. Our website is https://fast-switch.github.io, and my email
address is lijunnan@nudt.edu.cn.

====
P5 is developed in UM(user module) of NetMagic.
The structure of P5 is listed here:
-----top module: parser
		|
		-------------------------------------------------------------------------------------------------
				|					|				|		|			|			|					|
sub Module:		distributor			identifier		TCAM	ActionRAM	extractors	resultAccumulator	resultMux

distributor: used to distribute packets to distinct extractors;
identifier: used to send a type&State value from 8 results to TCAM;
TCAM: BV-based Algorithm;
ActionRAM: used to store parsing information, e.g. nextState, TypeLocation, FieldLocation and so on.
Extractor: used to extract specific fields from identified headers;
resultAccumulator: used to accumulate fields extracted by extractors to headerVectors;
resultMuxt: a mux to output headerVector one by one from 8 distinct headerVectors.


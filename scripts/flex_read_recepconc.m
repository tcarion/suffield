%----------------------------------------------------------
% FLEXPART Routine: read_recpconc 
%----------------------------------------------------------
% description
%   - reads concentrations at a point(s) as defined in 
%     the file RECEPTORS
% input
%   - head (data.frame output from read_header.r)
%   - optional: data units (1=conc (default), 2=pptv)
%   - time_ret (vector of julian dates from read_header.r)
%   - numreceptor (number of receptors)
% output
%   - storname - receptor names
%   - storloc - receptor locations
%   - concentrations at the receptors
%Author: Suresh Raja
%----------------------------------------------------------

function [receptorname,storeloc,conc]=flex_read_recepconc(header,unit,numreceptor,fin)
 
  %set defaults
  if unit==1
     filein='receptor_conc' 
  end
  if unit==2
     filein='receptor_pptv' 
  end
  
  time_ret=1:length(header.dates);
  
  fin=[header.path filein]
  fb=fopen(fin);
     
if fb<=0
   fprintf('******************************\n could not open file %s !\n******************************\n',fin);
else

  %receptorname=repmat({'Sample Text'}, numreceptor, 1);
  receptorname=[];
  rname=[];
  storename=[];
  %receptorloc=repmat(0,numreceptor,2);
  receptorloc=[];
  storeloc=[];
  %conc=repmat(0,length(time_ret),numreceptor);
  conc=[];
  
  %# read receptor names 
   rl=fread(fb,1,'int32');
  
  for nr=1:numreceptor
      rname=char(transpose(fread(fb,16,'char')));
      %rname=strrep(rname,' ',''); -this removes the spaCES-
      %receptorname={receptorname;rname};
      receptorname=[receptorname;rname];
  end
    
  rl=fread(fb,2,'int32');
  
  %# read receptor locations
  for nr = 1:numreceptor
      receptorloc=fread(fb,2,'float')';
      storeloc=[storeloc;receptorloc];
  end 
  rl=fread(fb,2,'int32');
  
  %#--- loop over dates
  dat_cnt=0; 
  for i = 1:length(time_ret)
     dat_cnt=dat_cnt+1;
     ns_cnt=0;
     itime=fread(fb,1,'int32');
     rl=fread(fb,2,'int32');

  %  # read all species
     for ns = 1:header.nspec
         ns_cnt=ns_cnt+1;
  %    # read all receptors
      rec_dump=fread(fb,numreceptor,'float')';
      rl=fread(fb,2,'int32');
      conc=[conc;rec_dump];
     end

 end
 
 fclose(fb)

end

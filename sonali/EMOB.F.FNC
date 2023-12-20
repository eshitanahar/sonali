CREATE OR REPLACE function EMOB.f return three_values is
    begin
      return
        three_values(1,sysdate,'hello');
    end;
/

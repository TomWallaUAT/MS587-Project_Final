/**
--CLASS: MS587
--NAME: Thomas Wallace
--PROJECT: FINAL PROJECT
--DESC: 
--		This is the SQL for Creating the table structure for my final project this is one of many SQL files
--=========================================================================================================
--	Change Date -INIT- Description of Change
--=========================================================================================================
--	10/04/2020 - TCW - INITIAL CREATION OF FUNCTION SCRIPT
--
*/


--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--CREATE OR ALTER FOR NEW INLINE FUNCTION
CREATE OR ALTER FUNCTION dbo.fnc_GetActivityID (@ACT_TYP_NM varchar(50))
RETURNS smallint
AS BEGIN
	/* ----------------------------------------------------------------------------
	Turns and Activity Typ Name into an ID (Looks up the ACT_TYP_ID by Name)
	---------------------------------------------------------------------------- */
	declare @IRet as smallint = 0
	
	SET @IRet = (Select T.ACT_TYP_ID FROM dbo.ACTIVITY_TYPES T WITH (NOLOCK) WHERE RTRIM(T.ACT_TYP_NM) = RTRIM(@ACT_TYP_NM))

	RETURN @IRet
END
Go


CREATE OR ALTER FUNCTION [dbo].[fnc_ProperCase] (@Text as varchar(max))
RETURNS varchar(max) 
as
BEGIN
	--=================================================================================
	--=================================================================================
	-- DATE			-	INITIALS - DESC
	--=================================================================================
	--07/13/2016	-	TCW	- Proper Case function for SQL Server 
	--=================================================================================
	declare @RSet bit;
	declare @ReturnValue varchar(8000);
	declare @i int;
	declare @c char(1);
	
	select @Rset = 1, @i =1, @ReturnValue='';
	
	IF (@Text is not null) BEGIN
		While (@i <= LEN(@text))
			select 
				@c=SUBSTRING(@Text,@i,1),
				@ReturnValue = @ReturnValue + CASE  when @Rset=1 then UPPER(@c) else LOWER(@c) end,
				@Rset = case when @c like '[a-zA-Z]' then 0 else 1 end,
				@i = @i +1
		    
			--Knowns to not replace
			Set @ReturnValue = replace (@ReturnValue,'n''T','n''t') --Address words like Won't Don't Can't etc...
			Set @ReturnValue = replace (@ReturnValue,'''S','''d')  --Address words with `d at the end
			Set @ReturnValue = replace (@ReturnValue,'''S','''s')  --Address words with `s at the end
			Set @ReturnValue = replace (@ReturnValue,'''Ll','''ll') --Address words with `ll at the end
			Set @ReturnValue = replace (@ReturnValue,'''Re','''re') --Address words with `re
			Set @ReturnValue = replace (@ReturnValue,'''Ve','''ve') --Address words with `ve
			Set @ReturnValue = replace (@ReturnValue,'I''M','I''m') --Address words with `I`m
			Set @ReturnValue = replace (@ReturnValue,'a''Am','a''am') --Address words with `a`am
			Set @ReturnValue = replace (@ReturnValue,'O''Clock','o''clock') --Address words with o`clock
			Set @ReturnValue = replace (@ReturnValue,'Po Box','P.O. Box') --Address words with PO Box
			Set @ReturnValue = LTrim(RTRIM(@ReturnValue))
	END 
	ELSE BEGIN
		Set @ReturnValue = null
	END
	Return @ReturnValue
END
GO


CREATE OR ALTER	function [dbo].[fnc_FormatPhone](@Phone varchar(30)) 
returns	varchar(30)
As
Begin
/* ----------------------------------------------------------------------------
Takes a phone number and formats in (999) 999-9999 format or just 999-9999 depending on length
of the number passed in.  Accepts up to Varchar(30) but it won't format
anything that long.  Each of the 'When's used in the case statement are popular db entries and are used to catch.
---------------------------------------------------------------------------- */

declare @FormattedPhone varchar(30)

SET 	@Phone = REPLACE(@Phone, '.', '-') --alot of entries use periods instead of dashes
SET		@Phone = REPLACE(@Phone,' -', '-')
SET     @Phone = REPLACE(@Phone,'- ','-') 
SET     @Phone = REPLACE(@Phone, '
','')-- This takes care of a carriage return at end of phone # Please do not move to line above
SET	@FormattedPhone =
	Case
	  When isNumeric(@Phone) = 1 Then
	    case
	      when len(@Phone) = 10 then '('+substring(@Phone, 1, 3)+')'+ ' ' +substring(@Phone, 4, 3)+ '-' +substring(@Phone, 7, 4)
	      when len(@Phone) = 7  then substring(@Phone, 1, 3)+ '-' +substring(@Phone, 4, 4)
	      else @Phone
	    end
	  When @phone like '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]' Then '('+substring(@Phone, 1, 3)+')'+ ' ' +substring(@Phone, 5, 3)+ '-' +substring(@Phone, 8, 4)
	  When @phone like '[0-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9][0-9]' Then '('+substring(@Phone, 1, 3)+')'+ ' ' +substring(@Phone, 5, 3)+ '-' +substring(@Phone, 9, 4)
	  When @phone like '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' Then '('+substring(@Phone, 1, 3)+')'+ ' ' +substring(@Phone, 5, 3)+ '-' +substring(@Phone, 9, 4)
	  Else @Phone
	End

return	@FormattedPhone

end
GO



CREATE OR ALTER FUNCTION [dbo].[fnc_StripSpcChars] (@Text as varchar(8000))
RETURNS varchar(8000)
as
BEGIN
	/* ----------------------------------------------------------------------------
	Strips out bad characters like ! @ # $ ^ * : ; ? /\ |  
	---------------------------------------------------------------------------- */
	declare @Ret varchar(8000);
	declare @i int;
	declare @c char(1);
	
	select @i =1, @Ret='';
	
	While (@i <= LEN(@text))
		select 
			@c=SUBSTRING(@Text,@i,1),
			@Ret = @Ret + case when @c like '[!@#$^*;:?/\|]' then '' else @c end,
			@i = @i +1
		Return LTrim(RTRIM(@Ret))
END
GO

create table professores (
id int primary key not null identity(1,1),
nome varchar(200),
sobrenome varchar(200),
data_cadastro date
)

insert into professores 
	(  [nome]
      ,[sobrenome]
      ,[data_cadastro])
  VALUES ('Arimatéia', 'Silva', GETDATE()),
		 ('Wesley', 'Souza', GETDATE()),
		 ('Cris', 'Nunes', GETDATE());

SELECT TOP (1000) 
	   [id]
	  ,[nome]
      ,[sobrenome]
      ,[data_cadastro]
  FROM [professores].[dbo].[professores]


CREATE TRIGGER TriggerProfessores
ON [professores].[dbo].[professores]
AFTER INSERT
AS

BEGIN	
    DECLARE @URL NVARCHAR(MAX) = 'http://127.0.0.1:5000/incluir';

	DECLARE @Object AS INT;
	DECLARE @ResponseText AS VARCHAR(8000);
	DECLARE @Id AS VARCHAR(8000);
	DECLARE @Nome AS VARCHAR(8000);
	DECLARE @Sobrenome AS VARCHAR(8000);
	DECLARE @Data_Cadastro AS VARCHAR(8000);
	DECLARE @Body AS VARCHAR(8000);
	
	SET @Id = (SELECT TOP (1) id from inserted)
	SET @Nome = (SELECT TOP (1) nome from inserted)
	SET @Sobrenome = (SELECT TOP (1) sobrenome from inserted)
	SET @Data_Cadastro = (SELECT TOP (1) data_cadastro from inserted)
	SET @Body = '{"id": "", "nome": "", "sobrenome":"", "data_cadastro":""}';

	SET @Body=JSON_MODIFY(@Body, '$.id', @Id)
	SET @Body=JSON_MODIFY(@Body, '$.nome', @Nome)
	SET @Body=JSON_MODIFY(@Body, '$.sobrenome', @Sobrenome)
	SET @Body=JSON_MODIFY(@Body, '$.data_cadastro', @Data_Cadastro)

	
	
	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'open', NULL, 'POST', @URL,'false'

	EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sp_OAMethod @Object, 'send', null, @Body
	EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT

	EXEC sp_OADestroy @Object

END

insert into professores 
	(  [nome]
      ,[sobrenome]
      ,[data_cadastro])
  VALUES ('Danillo', 'Rezende', GETDATE())
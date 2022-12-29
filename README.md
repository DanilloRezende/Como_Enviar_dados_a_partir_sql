# Como mandar uma requisição POST pelo SQL

## Objetivo

Dentro do escopo do nosso projeto, havia a necessidade de obter os novos registros inseridos no banco de dados do cliente.

## Contexto

Dentre as formas de obter o dado necessário e inseri-lo em nosso banco de dados, devemos considerar que estamos inserindo códigos dentro do banco de dados do nosso cliente portanto devemos inserir o mínimo de código possível para que não interferisse na performance atual do banco.

## Solução

Pensando em causar o mínimo de operações possíveis e apenas quando fosse necessário, optamos por adotar uma solução que por meio de uma trigger que será acionada sempre que houver uma inserção no banco de dados, ativasse uma procedure que irá enviar a partir do SQL  os dados para uma api externa.

## Primeiramente vamos criar uma tabela que servira de teste para nossa aplicação e inserir os valores.

```sql
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
```
  
## Uma vez criada a tabela devemos ativar as Ole Automation Procedures:
  
## Ole Automation
  
```sql
  sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO
```

## Criar Trigger

```sql
CREATE TRIGGER TesteBody
ON [professores].[dbo].[professores]
AFTER INSERT
AS
BEGIN
....
END
```

## Procedure

```sql
	
	DECLARE @URL NVARCHAR(MAX) = 'http://127.0.0.1:5000/incluir';

	DECLARE @Object AS INT;
	DECLARE @ResponseText AS VARCHAR(8000);
	DECLARE @Id AS VARCHAR(8000);
	DECLARE @Nome AS VARCHAR(8000);
	DECLARE @Sobrenome AS VARCHAR(8000);
	DECLARE @Data_Cadastro AS VARCHAR(8000);
	DECLARE @Body AS VARCHAR(8000);
	
	--Como não foi possível realizar um select para obter todos os valores inseridos 
	--no inserted optei por declarar todas as variaveis e atribuir uma por uma.
	SET @Id = (SELECT TOP (1) id from inserted)
	SET @Nome = (SELECT TOP (1) nome from inserted)
	SET @Sobrenome = (SELECT TOP (1) sobrenome from inserted)
	SET @Data_Cadastro = (SELECT TOP (1) data_cadastro from inserted)
	
	SET @Body = '{"id": "", "nome": "", "sobrenome":"", "data_cadastro":""}';
	
	--Uma vez com os dados obtidos de forma dinâmica da planilha inserted, atribuimos os
	--valores pelo json_modify
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
```
Para montar esta procedure utilizei como fonte os seguintes posts:
https://www.botreetechnologies.com/blog/how-to-fire-a-web-request-from-microsoft-sql-server/
https://www.zealousweb.com/calling-rest-api-from-sql-server-stored-procedure/

Tive alguma dificuldade em configurar objeto enviado para a api e graças ao seguinte vídeo consegui resolver:
https://www.youtube.com/watch?v=GFeR9m_AtpI&t=2240s



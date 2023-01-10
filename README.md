# Como enviar uma requisição POST pelo SQL

## Primeira TASK

E aew.

Bom sem me alongar muito, estou migrando de carreira como muita gente por ai, recebi uma oportunidade FODA e depois de uns 3 dias de muito desespero, café(nunca tomei mas parece que isso vem com a profissão nova), lagrimas, mais desespero finalmente um dia de glória =D. 

Concluí minha primeira task no trampo, bom esse foi um marco nessa nova carreira, e gostaria de registrar com o meu primeiro post aqui, então tá aqui um post sobre post a partir do MSSQL.

Imagino que devem haver formas mais simples, performáticas, complexas… enfim, tem uma área de comentário ai e me ajudaria muito cada conselho.

Chega de frescura, vamos a task…

Precisamos obter os dados de cada nova inserção no banco do cliente e envia-la para uma api externa… simples porém não podemos comprometer a performance do banco de dados do cliente então devemos inserir o mínimo possível de código e ativar a procedure o mínimo de vezes possível.

Então optamos por utilizar uma trigger, que a cada novo INSERT, irá ativar a nossa procedure.

 E o primeiro desafio foi ativar os OLE Automation dentro de uma imagem do MSSQL no Docker….

## Está solução não funciona no Docker

Depois de alguma pesquisa pude encontrar que o Win32::OLE module não pode ser utilizado em Linux por usar Windows API, por sorte neste projeto este não era um requisito então pude abandonar a ideia de seguir no docker. 

### Ativar Ole Automation

Caso queira se aprofundar mais no tema de OLE, indico este artigo [https://www.devmedia.com.br/artigo-sql-magazine-11-how-to-usando-objetos-ole-via-sql-server/7457](https://www.devmedia.com.br/artigo-sql-magazine-11-how-to-usando-objetos-ole-via-sql-server/7457)

Primeiro devemos garantir que estamos utilizando um user que pertença a server role admin.

Com o comando:

```sql
sp_helpsrvrolemember @srvrolename='sysadmin'

GO
```

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/405d9a64-91b1-45ac-9b02-85f29355cdbc/Untitled.png)

Feito isso, então ativamos os OLE 

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

Obtendo o seguinte retorno:

“

A opção de configuração 'show advanced options' foi alterada de 1 para 1. Execute a instrução RECONFIGURE para instalar.
A opção de configuração 'Ole Automation Procedures' foi alterada de 1 para 1. Execute a instrução RECONFIGURE para instalar.

“

Podemos agora criar a tabela em que realizaremos os testes

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

### Porque uma trigger??

Além dele ser ativado apenas quando necessário, ele nos permite utilizar como fonte de busca a tabela INSERTED, quando uma trigger é ativada são geradas 2 tabelas temporárias INSERTED e DELETED, onde respectivamente consta todos os valores que foram inseridos pela trigger e deletados.

### Trigger

```sql
CREATE TRIGGER TesteBody
ON [professores].[dbo].[professores]
AFTER INSERT
AS
BEGIN
....
END
```

E aqui um novo problema…

Não foi possível realizar uma busca mais otimizada dentro da tabela INSERTED, pois o MSSQL não permite que seja realizado um SELECT com mais de um resultado, então optei por realizar um SELECT para cada informação e atribui-la a uma variável. 

Procedure

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

Pelo código acima nós declaramos na variavel @URL qual o endpoint que será chamado, e qual o método será utilizado, como estamos enviando informações para uma api, utilizamos o método POST.

Dentro da variável @Body, criei um arquivo json e atribui os valores com o JSON_MODIFY.

Então, uma vez a trigger criada podemos adicionar um novo registro e verificar que a informação é enviada.

## Referencias

[https://www.botreetechnologies.com/blog/how-to-fire-a-web-request-from-microsoft-sql-server/](https://www.botreetechnologies.com/blog/how-to-fire-a-web-request-from-microsoft-sql-server/)

[https://www.zealousweb.com/calling-rest-api-from-sql-server-stored-procedure/](https://www.zealousweb.com/calling-rest-api-from-sql-server-stored-procedure/)

[https://www.youtube.com/watch?v=GFeR9m_AtpI&t=2240s](https://www.youtube.com/watch?v=GFeR9m_AtpI&t=2240s)

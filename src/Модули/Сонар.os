///////////////////////////////////////////////////////////////////
//
// Модуль с набором методов работы с SonarQube
// Используются методы rest-api sonarqube
// (C) TheShadowCo
//
///////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////
// Программный интерфейс
///////////////////////////////////////////////////////////////////

// ПолучитьПроекты
//	Возвращает набор проектов
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//
// Возвращаемое значение:
//   Соответствие   - Коллекция проектов
//		* Ключ - Строка - Код (Ключ) проекта
//		* Значение - Структура - Описание проекта
//			** Идентификатор - Строка - Идентификатор проекта
//			** Код - Строка - Код (Ключ) проекта
//
Функция ПолучитьПроекты(АдресСервера, Токен) Экспорт
	
	URLШаблон = "components/search?qualifiers=TRK&ps=500&p=%1";
	НомерСтраницы = 1;
	Проекты = Новый Соответствие();
	
	Пока Истина Цикл
		
		URL = СтрШаблон(URLШаблон, Формат(НомерСтраницы, "ЧГ="));
		Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL, "GET");
		
		Для Каждого ОписаниеПроекта Из Ответ.components Цикл

			НовыйПроект = Новый Структура();
			НовыйПроект.Вставить("Идентификатор", ОписаниеПроекта.id);
			НовыйПроект.Вставить("Код", ОписаниеПроекта.key);
			Проекты.Вставить(НовыйПроект.Код, НовыйПроект);
			
		КонецЦикла;
		
		Если БольшеНетДанных(Ответ) Тогда
			Прервать;
		КонецЕсли;

		НомерСтраницы = НомерСтраницы + 1;

	КонецЦикла;
	
	Возврат Проекты;

КонецФункции

// ПолучитьЗамечанияПроекта
//	Возвращает набор замечаний проекта по установленным отборам
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ОписаниеПроекта  - Структура - Описание проекта SonarQube
//		* Идентификатор - Строка - Идентификатор проекта
//		* Код - Строка - Код (Ключ) проекта
//  Статусы - Массив - Массив строковых идентификаторов статусов замечаний
//  ИзEDTВКонфигуратор - Булево - Признак необходимости преобразования замечаний между родительским проектом и дочерними
//
// Возвращаемое значение:
//   Соответствие   - Коллекция замечаний
//		* Ключ - Строка - Относительный путь к файлу, в котором зафиксировано замечание
//		* Значение - Структура - Описание проекта
//			** ПутьКФайлу - Строка -  Относительный путь к файлу, в котором зафиксировано замечание
//			** Ошибки - Соответствие - Набор зарегистрированных замечаний (ошибок)
//				*** Ключ - Строка - Хэш замечания
//				*** Значение - Структура - Описание замечания
//					**** ПутьКФайлу - Строка - Относительный путь к файлу, в котором зафиксировано замечание
//					**** Код - Строка - Ключ замечания
//					**** Хэш - Строка - Хэш замечания
//
Функция ПолучитьЗамечанияПроекта(АдресСервера, Токен, ОписаниеПроекта, Статусы, ИзEDTВКонфигуратор) Экспорт
	
	URLШаблон = "issues/search?ps=500&statuses=%1&projectUuids=%2&p=";
	Замечания = Новый Соответствие();
	
	Для Каждого Статус Из Статусы Цикл
		
		НомерСтраницы = 1;
		Пока Истина Цикл
			URL = СтрШаблон(URLШаблон, ВРег(СокрЛП(Статус)), ОписаниеПроекта.Идентификатор);
			Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");

			Для Каждого ОписаниеОшибки Из Ответ.issues Цикл
				
				ПутьКФайлу = СтрЗаменить(ОписаниеОшибки.component, ОписаниеПроекта.Код + ":", "");
				Если ИзEDTВКонфигуратор Тогда
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "configuration/src/", "src/configuration/");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ManagerModule.bsl", "/Ext/ManagerModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ObjectModule.bsl", "/Ext/ObjectModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/CommandModule.bsl", "/Ext/CommandModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/ValueManagerModule.bsl", "/Ext/ValueManagerModule.bsl");
					ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/configuration/Configuration", "/configuration/Ext");
					Если СтрНайти(ПутьКФайлу, "Forms") Тогда
						ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/Module.bsl", "/Ext/Form/Module.bsl");
					Иначе
						ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "/Module.bsl", "/Ext/Module.bsl");
					КонецЕсли;
				КонецЕсли;
				
				НовоеОписаниеОшибки = Новый Структура();
				НовоеОписаниеОшибки.Вставить("ПутьКФайлу", ПутьКФайлу);
				НовоеОписаниеОшибки.Вставить("Код", ОписаниеОшибки.key);
				Хэш = ПолучитьХэшЗамечания(ОписаниеОшибки, ПутьКФайлу);
				НовоеОписаниеОшибки.Вставить("Хэш", Хэш);
				
				ТекущийМодуль = Замечания.Получить(ПутьКФайлу);
				Если ТекущийМодуль = Неопределено Тогда 
					ТекущийМодуль = Новый Структура("ПутьКФайлу, Ошибки", ПутьКФайлу, Новый Соответствие());
				КонецЕсли;
				ТекущийМодуль.Ошибки.Вставить(Хэш, НовоеОписаниеОшибки);
				
				Замечания.Вставить(ПутьКФайлу, ТекущийМодуль);
				
			КонецЦикла;
			
			Если БольшеНетДанных(Ответ) Тогда
				Прервать;
			КонецЕсли;
			
			НомерСтраницы = НомерСтраницы + 1;
			
		КонецЦикла;

	КонецЦикла;
	
	Возврат Замечания;
	
КонецФункции

// ПолучитьЗакрываемыеЗамечания
//	Возвращает набор открытых замечаний проекта, которые необходимо закрыть
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ОписаниеПроекта  - Структура - Описание проекта SonarQube
//		* Идентификатор - Строка - Идентификатор проекта
//		* Код - Строка - Код (Ключ) проекта
//  ЗамечанияРодительскогоПроекта - Соответствие - Замечания для закрытия из родительского проекта. См. ПолучитьЗамечанияПроекта
//
// Возвращаемое значение:
//   Соответствие   - Коллекция замечаний
//		* Ключ - Строка - Хэш замечания
//		* Значение - Структура - Описание замечания
//			** ПутьКФайлу - Строка - Относительный путь к файлу, в котором зафиксировано замечание
//			** Код - Строка - Ключ замечания
//			** Хэш - Строка - Хэш замечания
//
Функция ПолучитьЗакрываемыеЗамечания(АдресСервера, Токен, ОписаниеПроекта, ЗамечанияРодительскогоПроекта) Экспорт
	
	URLШаблон = "issues/search?ps=500&statuses=OPEN,CONFIRMED,REOPENED&projectUuids=%1&componentKeys=%2&p=";
	Замечания = Новый Соответствие();
	
	Для Каждого МодульСЗмечаниями Из ЗамечанияРодительскогоПроекта Цикл
		
		URL = СтрШаблон(URLШаблон, ОписаниеПроекта.Идентификатор, ОписаниеПроекта.Код + ":" + МодульСЗмечаниями.Ключ);
		НомерСтраницы = 1;
		Пока Истина Цикл
			
			Ответ = ВыполнитьЗапрос(АдресСервера, Токен, URL + Формат(НомерСтраницы, "ЧГ="), "GET");
			Для Каждого ОписаниеОшибки Из Ответ.issues Цикл
				
				ПутьКФайлу = СтрЗаменить(ОписаниеОшибки.component, ОписаниеПроекта.Код + ":", "");
				Хэш = ПолучитьХэшЗамечания(ОписаниеОшибки, ПутьКФайлу);
				
				Если МодульСЗмечаниями.Значение.Ошибки.Получить(Хэш) = Неопределено Тогда
					Продолжить;
				КонецЕсли;

				НовоеОписаниеОшибки = Новый Структура();
				НовоеОписаниеОшибки.Вставить("ПутьКФайлу", ПутьКФайлу);
				НовоеОписаниеОшибки.Вставить("Код", ОписаниеОшибки.key);
				НовоеОписаниеОшибки.Вставить("Хэш", Хэш);
				Замечания.Вставить(Хэш, НовоеОписаниеОшибки);
				
			КонецЦикла;
			
			Если БольшеНетДанных(Ответ) Тогда
				Прервать;
			КонецЕсли;
			
			НомерСтраницы = НомерСтраницы + 1;
			
		КонецЦикла;

	КонецЦикла;
	
	Возврат Замечания;
	
КонецФункции

// ЗакрытьЗамечания
//	Выполняет закрытие замечаний: устанавливает признак "WONTFIX" со ссылкой на родительский проект
// Параметры:
//  АдресСервера  - Строка - Адрес (хост) сервера SonarQube
//  Токен  - Строка - Токен пользователя, от имени которого выполняются запросы к API
//  ЗакрываемыеЗамечания - Соответствие - Замечания, которые привнесены из родительского проекта и требуют закрытия. См. ПолучитьЗакрываемыеЗамечания
//  Комментарий - Строка - Текстовое сообщение, которое будет добавлено как коментарий к закрываемому замечанию
//
Процедура ЗакрытьЗамечания(АдресСервера, Токен, ЗакрываемыеЗамечания, Комментарий) Экспорт
	
	URL = СтрШаблон("issues/bulk_change?do_transition=wontfix&comment=%1&issues=", Комментарий);
	ЗамечанияДляОбработки = Новый Массив();
	Для Каждого Замечание Из ЗакрываемыеЗамечания Цикл
		
		Если ЗамечанияДляОбработки.Количество() = 100 Тогда
			ВыполнитьЗапрос(АдресСервера, Токен, URL + СтрСоединить(ЗамечанияДляОбработки, ","), "POST");
			ЗамечанияДляОбработки.Очистить();
		КонецЕсли;
		
		ЗамечанияДляОбработки.Добавить(Замечание.Значение.Идентификатор);
		
	КонецЦикла;
	
	Если ЗамечанияДляОбработки.Количество() Тогда
		ВыполнитьЗапрос(АдресСервера, Токен, URL + СтрСоединить(ЗамечанияДляОбработки, ","), "POST");
	КонецЕсли;
	
КонецПроцедуры

///////////////////////////////////////////////////////////////////
// Слубные процедуры и функции
///////////////////////////////////////////////////////////////////

Функция БольшеНетДанных(ОтветСервера)
	
	Возврат ОтветСервера.paging.pageSize * ОтветСервера.paging.pageIndex >= ОтветСервера.paging.total;

КонецФункции

Функция ПолучитьХэшЗамечания(ОписаниеОшибки, ПутьКФайлу)
	Возврат ПутьКФайлу + ОписаниеОшибки.rule 
			+ ?(ОписаниеОшибки.Свойство("textRange"), 
				"" + ОписаниеОшибки.textRange.startLine + ОписаниеОшибки.textRange.endLine 
					+ ОписаниеОшибки.textRange.startOffset + ОписаниеОшибки.textRange.endOffset, 
				"");
КонецФункции

Функция ВыполнитьЗапрос(АдресСервера, Токен, URL, Операция) 
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.АдресРесурса = "/api/" + URL;
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/json");
	
	HTTP = Новый HTTPСоединение(АдресСервера, , Токен);
	Если Операция = "GET" Тогда
		ОтветHTTP = HTTP.Получить(HTTPЗапрос);
	Иначе 
		ОтветHTTP = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
	КонецЕсли;
	
	Если ОтветHTTP.КодСостояния = 200 Тогда
		json = Новый ЧтениеJSON();
		json.УстановитьСтроку(ОтветHTTP.ПолучитьТелоКакСтроку());
		Возврат ПрочитатьJson(json);
	КонецЕсли;
	
	ВызватьИсключение 
		"Код ответа: " + ОтветHTTP.КодСостояния + Символы.ПС
		+ "Ответ: " + ОтветHTTP.ПолучитьТелоКакСтроку();
	
КонецФункции

import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Country = HasOneThrough_HasOne_BelongsTo_Fixture.Country
private typealias CountryProfile = HasOneThrough_HasOne_BelongsTo_Fixture.CountryProfile
private typealias Continent = HasOneThrough_HasOne_BelongsTo_Fixture.Continent

class HasOneThroughIncludingOptionalRequest_HasOne_BelongsToOptional_Tests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .including(optional: Country.continent)
                .fetchAll(db)
            
            assertEqualSQL(lastSQLQuery, """
                SELECT "countries".*, "continents".* \
                FROM "countries" \
                LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                """)

            assertMatch(graph, [
                (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                (["code": "MX", "name": "Mexico"], nil),
                (["code": "AA", "name": "Atlantis"], nil),
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Country
                    .filter(Column("code") != "DE")
                    .including(optional: Country.continent)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("countries"."code" <> 'DE')
                    """)

                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .including(optional: Country.continent)
                    .filter(Column("code") != "DE")
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("countries"."code" <> 'DE')
                    """)

                assertMatch(graph, [
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("name").desc)
                    .including(optional: Country.continent)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    ORDER BY "countries"."name" DESC
                    """)
                
                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .including(optional: Country.continent)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    ORDER BY "countries"."name" DESC
                    """)

                assertMatch(graph, [
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
        }
    }
    
    func testMiddleRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let middleAssociation = Country.profile.filter(Column("currency") != "EUR")
                let association = Country.hasOne(CountryProfile.continent, through: middleAssociation)
                let graph = try Country
                    .including(optional: association)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON (("countryProfiles"."countryCode" = "countries"."code") AND ("countryProfiles"."currency" <> 'EUR')) \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], nil),
                    (["code": "FR", "name": "France"], nil),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                let middleAssociation = Country.profile.order(Column("currency").desc)
                let association = Country.hasOne(CountryProfile.continent, through: middleAssociation)
                let graph = try Country
                    .including(optional: association)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let graph = try Country
                    .including(optional: Country.continent.filter(Column("name") != "America"))
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON (("continents"."id" = "countryProfiles"."continentId") AND ("continents"."name" <> 'America'))
                    """)
                
                assertMatch(graph, [
                    (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    (["code": "US", "name": "United States"], nil),
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    ])
            }
            
            do {
                let graph = try Country
                    .including(optional: Country.continent.order(Column("name")))
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    ORDER BY "continents"."name"
                    """)
                
                assertMatch(graph, [
                    (["code": "MX", "name": "Mexico"], nil),
                    (["code": "AA", "name": "Atlantis"], nil),
                    (["code": "US", "name": "United States"], ["id": 2, "name": "America"]),
                    (["code": "DE", "name": "Germany"], ["id": 1, "name": "Europe"]),
                    (["code": "FR", "name": "France"], ["id": 1, "name": "Europe"]),
                    ])
            }
        }
    }
    
    func testRecursion() throws {
        struct Person : TableMapping {
            static let databaseTableName = "persons"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "persons") { t in
                t.column("id", .integer).primaryKey()
                t.column("parentId", .integer).references("persons")
                t.column("childId", .integer).references("persons")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let middleAssociation = Person.hasOne(Person.self, using: ForeignKey([Column("childId")]))
                let rightAssociation = Person.belongsTo(Person.self, using: ForeignKey([Column("parentId")]))
                let association = Person.hasOne(rightAssociation, through: middleAssociation)
                let request = Person.including(optional: association)
                try assertEqualSQL(db, request, """
                    SELECT "persons1".*, "persons3".* \
                    FROM "persons" "persons1" \
                    LEFT JOIN "persons" "persons2" ON ("persons2"."childId" = "persons1"."id") \
                    LEFT JOIN "persons" "persons3" ON ("persons3"."id" = "persons2"."parentId")
                    """)
            }
        }
    }
    
    func testLeftAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let countryRef = TableReference(alias: "c")
                let request = Country.all()
                    .identified(by: countryRef)
                    .filter(Column("code") != "DE")
                    .including(optional: Country.continent)
                try assertEqualSQL(db, request, """
                    SELECT "c".*, "continents".* \
                    FROM "countries" "c" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "c"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("c"."code" <> 'DE')
                    """)
            }
            
            do {
                // alias last
                let countryRef = TableReference(alias: "c")
                let request = Country
                    .filter(Column("code") != "DE")
                    .including(optional: Country.continent)
                    .identified(by: countryRef)
                try assertEqualSQL(db, request, """
                    SELECT "c".*, "continents".* \
                    FROM "countries" "c" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "c"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("c"."code" <> 'DE')
                    """)
            }
            
            do {
                // alias with table name (TODO: port this test to all testLeftAlias() tests)
                let countryRef = TableReference(alias: "countries")
                let request = Country.all()
                    .identified(by: countryRef)
                    .including(optional: Country.continent)
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
    
    func testMiddleAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let profileRef = TableReference(alias: "a")
                let association = Country.hasOne(CountryProfile.continent, through: Country.profile.identified(by: profileRef))
                let request = Country.including(optional: association)
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" "a" ON ("a"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "a"."continentId")
                    """)
            }
            do {
                // alias with table name
                let profileRef = TableReference(alias: "countryProfiles")
                let association = Country.hasOne(CountryProfile.continent, through: Country.profile.identified(by: profileRef))
                let request = Country.including(optional: association)
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let continentRef = TableReference(alias: "a")
                let request = Country
                    .including(optional: Country.continent
                        .identified(by: continentRef)
                        .filter(Column("name") != "America"))
                    .order(continentRef[Column("name")])
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "a".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" "a" ON (("a"."id" = "countryProfiles"."continentId") AND ("a"."name" <> 'America')) \
                    ORDER BY "a"."name"
                    """)
            }
            
            do {
                // alias last
                let continentRef = TableReference(alias: "a")
                let request = Country
                    .including(optional: Country.continent
                        .order(Column("name"))
                        .identified(by: continentRef))
                    .filter(continentRef[Column("name")] != "America")
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "a".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" "a" ON ("a"."id" = "countryProfiles"."continentId") \
                    WHERE ("a"."name" <> 'America') \
                    ORDER BY "a"."name"
                    """)
            }
            
            do {
                // alias with table name (TODO: port this test to all testRightAlias() tests)
                let continentRef = TableReference(alias: "continents")
                let request = Country.including(optional: Country.continent.identified(by: continentRef))
                try assertEqualSQL(db, request, """
                    SELECT "countries".*, "continents".* \
                    FROM "countries" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    LEFT JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
            
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let countryRef = TableReference(alias: "CONTINENTS") // Create name conflict
                let request = Country.including(optional: Country.continent).identified(by: countryRef)
                try assertEqualSQL(db, request, """
                    SELECT "CONTINENTS".*, "continents1".* \
                    FROM "countries" "CONTINENTS" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "CONTINENTS"."code") \
                    LEFT JOIN "continents" "continents1" ON ("continents1"."id" = "countryProfiles"."continentId")
                    """)
            }
            
            do {
                // alias right
                let continentRef = TableReference(alias: "COUNTRIES") // Create name conflict
                let request = Country.including(optional: Country.continent.identified(by: continentRef))
                try assertEqualSQL(db, request, """
                    SELECT "countries1".*, "COUNTRIES".* \
                    FROM "countries" "countries1" \
                    LEFT JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries1"."code") \
                    LEFT JOIN "continents" "COUNTRIES" ON ("COUNTRIES"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
    
    func testConflictingAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let countryRef = TableReference(alias: "A")
                let continentRef = TableReference(alias: "a")
                let request = Country.including(optional: Country.continent.identified(by: continentRef)).identified(by: countryRef)
                _ = try request.fetchAll(db)
                XCTFail("Expected error")
            } catch let error as DatabaseError {
                XCTAssertEqual(error.resultCode, .SQLITE_ERROR)
                XCTAssertEqual(error.message!, "ambiguous alias: A")
                XCTAssertNil(error.sql)
                XCTAssertEqual(error.description, "SQLite error 1: ambiguous alias: A")
            }
        }
    }
}

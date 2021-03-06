"
When no receiver class is known, I'm the right model. I store all temporary variables, instance variables of the selected class and all selectors in system. For performance reasons I only collect selectors when at least one character is known.
"
Class {
	#name : #NECUntypedModel,
	#superclass : #NECModel,
	#instVars : [
		'instVars',
		'localVars',
		'includeVariables',
		'includeSelectors',
		'classVars'
	],
	#category : #'NECompletion-Model'
}

{ #category : #'instance creation' }
NECUntypedModel class >> class: aClass temporaries: aCollection [ 
	^self 
		class: aClass
		temporaries: aCollection
		additionals: #()
		variables: true
		selectors: true
]

{ #category : #'instance creation' }
NECUntypedModel class >> class: aClass temporaries: aCollection additionals: additionalCollection variables: variablesBoolean selectors: selectorsBoolean [ 
	| newInstance |
	newInstance := self basicNew initialize.
	newInstance 
		setClass: aClass
		temporaries: aCollection
		additionals: additionalCollection
		variables: variablesBoolean
		selectors: selectorsBoolean.
	^ newInstance
]

{ #category : #private }
NECUntypedModel >> addAdditionals: aCollection [ 
	aCollection
		ifNotNil: [aCollection
				do: [:each | each isLocal
						ifTrue: [localVars add: each value]
						ifFalse: [each isInstance
								ifTrue: [instVars add: each value]
								ifFalse: [each isSelector
										ifTrue: [selectors add: each value]]]]]
]

{ #category : #private }
NECUntypedModel >> addSelectors [
	self initializeSelectors.
	self addToEntries: selectors
]

{ #category : #private }
NECUntypedModel >> addVariables [
	includeVariables
		ifFalse: [^ self].
	self addToEntries: localVars.
	self addToEntries: instVars.
	self addToEntries: classVars
]

{ #category : #initialization }
NECUntypedModel >> initialize [
	super initialize.
	localVars := SortedCollection new.
	instVars := SortedCollection new.
	classVars := SortedCollection new.
	includeSelectors := true.
	includeVariables := true.
]

{ #category : #initialization }
NECUntypedModel >> initializeClassVars [
	(clazz isNil or: [ includeVariables not ]) ifTrue: [ ^ self ].
	classVars := clazz instanceSide allClassVarNames asSortedCollection.
	classVars := classVars collect: 
		[ :each | 
		NECClassVarEntry contents: each ]
]

{ #category : #initialization }
NECUntypedModel >> initializeInstVars [
	(clazz isNil or: [ includeVariables not ]) ifTrue: [ ^ self ].
	instVars := clazz allInstVarNames asSortedCollection.
	instVars := instVars collect: 
		[ :each |  NECInstVarEntry contents: each ].
	instVars add: (NECSelfEntry 
			contents: 'self'
			type: #self).
	instVars add: (NECSuperEntry 
			contents: 'super'
			type: #super)
]

{ #category : #private }
NECUntypedModel >> initializeSelectors [
	| case |
	self resetSelectors.
	narrowString size < 2 ifTrue: [ ^ self ].
	case :=  NECPreferences caseSensitive.
	includeSelectors
		ifTrue: [ Symbol selectorTable do: [ :symbol | | toadd | 
					"for small strings, we do not do substring matching as we get too many matches (slow)"
					toadd := narrowString size < 3 
						ifTrue: [ symbol beginsWithEmpty: narrowString caseSensitive: case] 
						ifFalse: [symbol includesSubstring: narrowString caseSensitive: case].
					toadd ifTrue: [ selectors add: (NECSelectorEntry contents: symbol type: #selector) ] ] ].
	includeVariables
		ifTrue: [ Smalltalk globals keysDo: [ :symbol  | 
					(symbol includesSubstring: narrowString caseSensitive: case)
						ifTrue: [ selectors add: (NECGlobalEntry contents: symbol ) ] ] ].
	self sortSelectors
]

{ #category : #private }
NECUntypedModel >> loadEntries [
	self addVariables;
		addSelectors
]

{ #category : #accessing }
NECUntypedModel >> message [
	^ (includeSelectors and: [ narrowString isEmpty ]) 
		ifTrue: 
			[ selectors size = 500 
				ifTrue: [ 'more...' ]
				ifFalse: [ 'press key for selectors' ] ]
		ifFalse: [ super message ]
]

{ #category : #initialization }
NECUntypedModel >> narrowString: aString [ 
	(narrowString isEmpty
			or: [aString isEmpty
			or: [aString first ~= narrowString first]])
		ifTrue: [self reset].
	super narrowString: aString
]

{ #category : #action }
NECUntypedModel >> narrowWith: aString [ 
	self narrowString: aString.
	self resetEntries.
	self addVariables.
	self addSelectors
]

{ #category : #initialization }
NECUntypedModel >> setClass: aClass temporaries: aCollection additionals: additionalCollection variables: variablesBoolean selectors: selectorsBoolean [ 
	includeVariables := variablesBoolean.
	includeSelectors := selectorsBoolean.
	clazz := aClass.
	self initializeInstVars.
	self initializeClassVars.
	includeVariables 
		ifTrue: [ 
			localVars := aCollection.
			self addAdditionals: additionalCollection ]
		ifFalse: [ localVars := OrderedCollection new ].
	self resetEntries.
]

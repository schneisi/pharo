"
I'm a simple test ressource for test purposes
"
Class {
	#name : #SimpleTestResourceB,
	#superclass : #SimpleTestResource,
	#category : #'SUnit-Tests-Resources'
}

{ #category : #accessing }
SimpleTestResourceB class >> resources [
	^Array with: SimpleTestResourceA1 with: SimpleTestResourceB1
]

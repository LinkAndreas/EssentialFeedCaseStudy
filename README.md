Exercise-Repository as part of the iOS Lead Essentials Training 
- Reference: https://github.com/essentialdevelopercom/essential-feed-case-study

# BDD Spec

Story: Customer requests to see their image feed

## Narrative #1:

```
As an online customer
I want the app to atuomatically load my latest image feed
So I can always enjoy the latest images of my friends
```

Scenarios (Acceptance criteria):

```
Given the customer has connectivity
When the customer requests to see their feed
Then the app should display the latest feed from remote
And replace the cache with the new feed
```

## Narrative #2:

```
As an offline customer
I want the app to show the latest saved version of my feed
So I can always enjoy images of my friends
```

Scenarios (Acceptance criteria):

```
Given the customer doesn't have connectivity
And there is a cached version of the feed
And the cache is less than seven days old
When the customer requests their feed
Then the app should display the latest feed saved
```

```
Given the customer doesn't have connectivity
And there is a cached version of the feed
And the cache is seven days old or more
When the customer requests their feed
Then the app should display an error message
```

```
Given the customer doesn't have connectivity
And the cache is empty
When the customer requests their feed
Then the app should display an error message
```

## Use Cases:

### Load Feed from Remote Use Case:
Data: 
	- URL

Primary Course (happy path):
1. Execute "Load Image Feed" command with above data
2. System downloads data from URL
3. System validates downloaded data
4. System creates image feed from valid data
5. System delivers image feed

Invalid data - error course (sad path):
1. System delivers invalid data error

No connectivity - error course (sad path):
1. System delivers connectivity error

### Load Feed from Cache Use Case:

Primary Course (happy path):
1. Execute "Load Image Feed" command with above data
2. System retrieves feed data from cache
3. System validates cache is less than seven days old
4. System creates image feed from cached data
5. System delivers image feed

Retrieval Error course (sad path):
1. System delivers error

Expired cache - course (sad path):
1. System delivers no image feed

Empty cache - course (sad path):
1. System delivers no image feed

### Validate Feed Cache Use Case:

Primary Course (happy path):
1. Execute "Validate Cache" command with above data
2. System retrieves feed data from cache
3. System validates cache is less than seven days old

Retrieval Error course (sad path):
1. System deletes cache

Expired cache - course (sad path):
1. System deletes cache

Empty cache - course (sad path):
1. System delivers no image feed

### Cache Feed Use Case:
Data: 
	- Image Feed

Primary Course (happy path):
1. Execute "Save Image Feed" command with above data
2. System deletes old cached data
3. System encodes new image feed
4. System timestamps new cache
5. System saves new cache data
6. System delivers success message

Deleting - error course (sad path):
1. System deletes cache
2. System delivers error

Saving - error course (sad path):
1. System delivers error


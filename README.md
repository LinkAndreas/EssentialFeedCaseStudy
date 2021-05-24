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
1. Execute "Load Feed Items" command with above data
2. System downloads data from URL
3. System validates downloaded data
4. System creates feed items from valid data
5. System delivers feed items

Invalid data - error course (sad path):
1. System delivers invalid data error

No connectivity - error course (sad path):
1. System delivers connectivity error

### Load Feed from Cache Use Case:

Primary Course (happy path):
1. Execute "Load Feed Items" command with above data
2. System fetches feed data from cache
3. System validates cache is less than seven days old
4. System creates feed items from cached data
5. System delivers feed items

Error course (sad path):
1. System delivers error

Expired cache - course (sad path):
1. System deletes cache
2. System delivers no feed items

Empty cache - course (sad path):
1. System delivers no feed items

### Save Cache Use Case:
Data: 
	- Feed Items

Primary Course (happy path):
1. Execute "Dave Feed Items" command with above data
2. System deletes old cached data
3. System encodes new feed items
4. System timestamps new cache
5. System saves new cache data
6. System delivers success message

Deleting - error course (sad path):
1. System deletes cache
2. System delivers error

Saving - error course (sad path):
1. System delivers error


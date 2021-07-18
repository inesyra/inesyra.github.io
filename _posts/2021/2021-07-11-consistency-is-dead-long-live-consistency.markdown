---
layout: "post"
title: "Consistency is dead. Long live consistency."
date: "2021-07-11 13:45"
excerpt: "One of the projects I am involved in provided me with a ticket to change an Android form contents and adapt it to fresh requirements."
comments: true
---

One of the projects I am involved in provided me with a ticket to change an Android form contents and adapt it to fresh requirements.

The gist of it was as follows: update a form with two text input fields and a spinner into one text input.
The new value for the remaining text input would contain two pieces of information: a profile id and a receipt number.

When the form is "submitted" the activity should read the profile id and make a database query to fetch the corresponding entity row.
This meant that the code needed to be executed on a non-main thread. For this project, it meant using an AsyncTask, a class that has been deprecated in the latest versions of Android.

My inner daemon started to get all sort of ideas: Thread, Handler, HandlerThread, Executor, RX, etc. In true developer culture, I chose HandlerThread.
My motivation was to introduce a more modern solution.

The advanges of using HandlerThread seemed transparent:
- Robust solution with fewer lines of code compared to AsyncTask
- Future-proof implementation since this is the new recommended way of handling background work

However, the disadvantages weighed heavily and boy did I regret the decision.
- The code looked out of place since it broke existing consistency
- It increased code opacity by introducing new concepts. The multithreading topic in Android is too vast and newer libraries aim to overcome past drawbacks at the cost of introducing newer and newer ideas. If I were to rewrite the same code with a better solution I would opt for an Executor + runOnUiThread.
- It increased the burden on other programmers to familiarize themselves with foreign code


```java
// The code is pretty straightforward: when some button is clicked, do some action in the background and return the result to the UI thread
public class FooScreen extends ... {
    ...
    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        ...
        binding.transactionButton.setOnClickListener(this::doTransaction);
    }

    private void doTransaction(View view) {
        // String receipt = binding.receiptNoText.getText().toString();
        // String profileId = receipt.substring(0, 2);
        // String receiptNumber = receipt.substring(2);

        findProfileAndAmount(profileId, receipt, new Handler(Looper.getMainLooper()) { // The main looper will execute on the desired main thread
            @Override
            public void handleMessage(@NonNull Message msg) {
                super.handleMessage(msg);

                FooScreenQueryResult result = (FooScreenQueryResult) msg.obj;
                if (null == result.profile) {
                    Log.e(TAG, "Could not find payment profile based on given ID " + profileId);
                    return;
                }

                // Intent intent = new Intent(getActivity(), BarActivity.class);
                // intent.putExtra(...);
                // startActivityForResult(intent, Transaction.TRANS_CODE);
            }
        });
    }

    private void findProfileAndAmount(String profileId, String receipt, Handler responseHandler) { // This should have been an AsyncTask class
        profileThread = new HandlerThread("Profile");
        profileThread.start();

        new Handler(profileThread.getLooper()).post(() -> {
            FooScreenQueryResult queryResult = new FooScreenQueryResult();

            // List<DBObject> profileList = DB.getPaymentProfile().selectBy(Profile.COLS.ID, profileId);
            // if (profileList.size() > 0) {
            //     queryResult.profile = (Profile) profileList.get(0);
            // }
            //
            // List<DBObject> batchTransactionList = DB.getBatchTransaction().selectBy(BatchTransaction.COLS.RECEIPT_NO, receipt);
            // if (batchTransactionList.size() > 0) {
            //     queryResult.amount = ((BatchTransaction) batchTransactionList.get(0)).getAmount();
            // }

            responseHandler.obtainMessage(0, queryResult).sendToTarget(); // Send the found profile to the response handler
        });
    }

    private static class FooScreenQueryResult {
        public Profile profile;
        public String amount;
    }
}
```

As I was writing the new lines of code, I could feel them pointing back at me and laughing. "This idiot is writing a HandlerThread in a 100% AsyncTask codebase; what a noob!".


The point of this error would be to always strive for consistency as opposed to trying out new shiny things.
This makes it easier for everyone involved to navigate code and modify it as needed.
Keep things simple. When a refactoring is required, take time to discuss it with your team and agree together on a plan of action.

To conclude, you should always prefer the boring, old solution to new tricks. Learning is encouraged and essential for programmers and more learning happens by self study but projects involve a community that runs smoothly if everyone is on the same page.
Make everyone's life easier by applying common solutions.

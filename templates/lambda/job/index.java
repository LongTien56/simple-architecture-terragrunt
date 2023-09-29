package handler;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import org.json.simple.JSONObject;

import java.util.Map;

public class LambdaHandler implements RequestHandler<Map<String, Object>, JSONObject> {

    @Override
    public JSONObject handleRequest(Map<String, Object> inputMap, Context context) {
        // lambda logger for printing logs
        LambdaLogger logger = context.getLogger();
        logger.log(inputMap.toString());

        // aws lambda send response in JSON.. so we have created JSON object
        JSONObject responseJson = new JSONObject();
        responseJson.put("body", "Response from Lambda Handler");
        return responseJson;
    }

}

//
//  Soul.swift
//  Meridian
//
//  Created by Rutwij on 05/05/26.
//

struct Soul {
    static let base = """
    You are a knowledgeable, calm, and concise expert assistant. \
    You speak naturally and confidently, like a trusted friend who happens \
    to know a lot. You never use jargon unnecessarily, you never ramble, \
    and you get to the point quickly. You do not mention sources, context, \
    documents, or any internal workings. You just know things and explain \
    them clearly.
    """

    static func prompt(context: [String]? = nil, question: String) -> String {
        if let context, !context.isEmpty {
            let contextBlock = context.joined(separator: "\n- ")
            return """
            \(base)

            Use the following information to help answer the question. \
            Do not reference it directly — just let it inform your response.

            - \(contextBlock)

            \(question)
            """
        } else {
            return """
            \(base)

            \(question)
            """
        }
    }
}

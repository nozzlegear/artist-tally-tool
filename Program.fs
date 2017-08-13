// Learn more about F# at http://fsharp.org
namespace Program

open System
open System.Threading
open System.Collections.Generic
open System.Net
open Newtonsoft.Json
open Utils

module MainModule =

    type TallyResponse = {
        since: int64
        summary: Dictionary<string, int>
    }

    type EmailTally = {
        artist: string
        count: int
    }

    type SwuRecipient = {
        name: string
        address: string
    }

    type SwuSender = {
        name: string
        address: string
        replyTo: string
    }

    type SwuTallyTemplateData = {
        date: string
        tally: EmailTally seq
    }

    type SwuMessage = {
        template: string
        recipient: SwuRecipient
        cc: SwuRecipient list
        sender: SwuSender
        template_data: SwuTallyTemplateData
    }

    type SwuResponse = {
        test: bool
    }

    let swuKey = Env.varRequired "ARTIST_TALLY_SWU_KEY"
    let swuTemplateId = Env.varRequired "ARTIST_TALLY_SWU_TEMPLATE_ID"
    let emailDomain = Env.varRequired "ARTIST_TALLY_EMAIL_DOMAIN"
    let apiDomain = Env.varDefault "ARTIST_TALLY_API_DOMAIN" "localhost:3000"
    let isLive = (Env.varDefault "ARTIST_TALLY_ENV" "development") = "production"

    let buildMessage method url authHeader body = 
        let message = new Http.HttpRequestMessage (Method = method, RequestUri = Uri url)

        body
        |> Option.iter (fun body ->
            let serialized = JsonConvert.SerializeObject body
            let content = new Http.StringContent (serialized, Text.Encoding.UTF8, "application/json")

            message.Content <- content)

        authHeader
        |> Option.iter (fun header -> message.Headers.Authorization <- header)

        message

    let makeRequest message = async {
        use client = new Http.HttpClient ()    
        let! response = client.SendAsync message |> Async.AwaitTask

        response.EnsureSuccessStatusCode () |> ignore 

        let! body = response.Content.ReadAsStringAsync () |> Async.AwaitTask

        return body
    }

    let midnight () = DateTime.Now.Date

    let midnightYesterday () = midnight().AddDays -1.

    let toUnixTimestamp date = DateTimeOffset(date).ToUnixTimeMilliseconds()

    let deserialize<'T> body = JsonConvert.DeserializeObject<'T> body 

    let convertResponseToTally (summary: Dictionary<string, int>) = 
        summary |> Seq.map(fun kvp -> { artist = kvp.Key; count = kvp.Value })

    let formatEmail name = sprintf "%s@%s" name emailDomain

    let emailRecipient = 
        if isLive then { name = "Mike"; address = formatEmail "mikef" }
        else { name = "Joshua Harms"; address = formatEmail "josh" }

    let emailCcs =
        if isLive then 
            [
                {
                    name = "Tim"
                    address = formatEmail "tim"
                }
                {
                    name = "Jeanette"
                    address = formatEmail "jeanette"
                }
                {
                    name = "Joshua Harms"
                    address = formatEmail "josh"
                }
            ]
        else []    

    let sendEmailMessage (tally: seq<EmailTally>) = async {
        let base64HeaderValue = sprintf "%s:" swuKey |> Text.Encoding.UTF8.GetBytes |> Convert.ToBase64String
        let header = Http.Headers.AuthenticationHeaderValue ("Basic", base64HeaderValue)
        let url = "https://api.sendwithus.com/api/v1/send"
        let date = DateTime.Now.ToString ("MMM dd, yyyy")
        let message = 
            {
                template = swuTemplateId
                recipient = emailRecipient
                cc = emailCcs
                sender = 
                    {
                        name = "KMSignalR Superintendent"
                        address = formatEmail "superintendent"
                        replyTo = formatEmail "superintendent" 
                    }
                template_data = 
                    {
                        date = date
                        tally = tally
                    }
            }
        let! response =
            buildMessage Http.HttpMethod.Post url (Some header) (Some message)
            |> makeRequest
        
        return response |> deserialize<SwuResponse>
    }

    [<EntryPoint>]
    let main argv =
        let since = midnightYesterday () |> toUnixTimestamp
        let until = midnight () |> toUnixTimestamp
        let protocol = if isLive then "https" else "http"
        let url = sprintf "%s://%s/api/v1/orders/portraits/artist-tally?since=%i&until=%i" protocol apiDomain since until
        let summaryResponse =
            buildMessage Http.HttpMethod.Get url None None
            |> makeRequest
            |> Async.RunSynchronously
            |> deserialize

        match summaryResponse.summary.Count with
        | 0 -> printfn "Tally response contained an empty summary. Was the `since` parameter (%i) incorrect?" since
        | _ -> summaryResponse.summary
               |> Seq.iter (fun kvp -> printfn "%s: %i portraits" kvp.Key kvp.Value)

        let emailResponse =
            summaryResponse.summary
            |> convertResponseToTally
            |> sendEmailMessage
            |> Async.RunSynchronously

        0 // return an integer exit code

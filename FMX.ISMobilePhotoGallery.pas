unit FMX.ISMobilePhotoGallery;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.IOUtils, System.Messaging,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Effects, FMX.Utils, FMX.Surfaces,

  {$IFDEF ANDROID}
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.provider,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net,
  Androidapi.JNI.App,
  AndroidAPI.jNI.OS,
  Androidapi.JNIBridge,
  FMX.Helpers.Android,
  IdUri,
  Androidapi.Helpers,
  FMX.Platform.Android,
  {$ENDIF}

  FMX.Platform;

type

   TISTakePhoto = Procedure (Sender : TObject; aBitmap : TBitmap) Of Object;

   [ComponentPlatformsAttribute (pfidAndroid)]
   TISPhotoGallery = Class(TComponent)
      Private
         FRequestCode   : Integer;
         FMsgID         : Integer;
         FAllowMultiple : Boolean;
         FOnTakePhoto   : TISTakePhoto;
         FOnCancel      : TNotifyEvent;
         FOnError       : TNotifyEvent;
         {$IFDEF ANDROID}
         procedure HandleActivityMessage(const Sender: TObject; const M: TMessage);
         Procedure OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent);
         {$ENDIF}
      Public
         Constructor Create(aOwner : TComponent); Override;
         Procedure TakePhotoFromGallery;
      Published
         Property AllowMultiple : Boolean      Read FAllowMultiple Write FAllowMultiple;
         Property RequestCode   : Integer      Read FRequestCode   Write FRequestCode;
         Property OnTakePhoto   : TISTakePhoto Read FOnTakePhoto   Write FOnTakePhoto;
         Property OnCancel      : TNotifyEvent Read FOnCancel      Write FOnCancel;
         Property OnError       : TNotifyEvent Read FOnError       Write FOnError;
      End;

Procedure Register;

implementation

{ TISPhotoGallery }

constructor TISPhotoGallery.Create(aOwner: TComponent);
begin
inherited;
FRequestCode := 1122;
end;

procedure TISPhotoGallery.TakePhotoFromGallery;
{$IFDEF ANDROID}
Var
   Intent : JIntent;
{$ENDIF}
begin
{$IFDEF ANDROID}
FMsgID := TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification, HandleActivityMessage);
Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_PICK);
intent.setType(StringToJString('image/*'));
intent.setAction(TjIntent.JavaClass.ACTION_GET_CONTENT);
Intent.putExtra(TJIntent.JavaClass.EXTRA_ALLOW_MULTIPLE, FAllowMultiple);
TAndroidHelper.Activity.startActivityForResult(Intent, FRequestCode);
{$ENDIF}
end;

{$IFDEF ANDROID}
procedure TISPhotoGallery.HandleActivityMessage(const Sender: TObject; const M: TMessage);
begin
if M is TMessageResultNotification then
   OnActivityResult(TMessageResultNotification(M).RequestCode, TMessageResultNotification(M).ResultCode, TMessageResultNotification(M).Value);
end;

Procedure TISPhotoGallery.OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent);

   procedure URI2Bitmap(const AURI: Jnet_Uri; const ABitmap: TBitmap);
   var
      Bitmap  : JBitmap;
      Surface : TBitmapSurface;
   begin
   Bitmap      := TJBitmapFactory.JavaClass.decodeStream(TAndroidHelper.Context.getContentResolver.openInputStream(AURI));
   Surface     := TBitmapSurface.Create;
   jBitmapToSurface(Bitmap, Surface);
   ABitmap.Assign(Surface);
   Surface.DisposeOf;
   if Assigned(FOnTakePhoto) then FOnTakePhoto(Self, ABitmap);
   end;

Var
   I     : Integer;
   Photo : TBitmap;
begin
TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FMsgID);
if RequestCode = FRequestCode then
   begin
   if ResultCode =  TJActivity.JavaClass.RESULT_OK then
      begin
      if Assigned(Data) Then
         Begin
         Photo := TBitmap.Create;
         If Assigned(Data.getClipData) then
            begin
            for I := 0 to Data.getClipData.getItemCount-1 do
               Begin
               URI2Bitmap(Data.getClipData.getItemAt(I).getUri, Photo);
               End;
            end
         Else
            if Assigned(Data.getData) then
               Begin
               URI2Bitmap(Data.getData, Photo);
               End;
         Photo.DisposeOf;
         End;
      end
   else
      if (ResultCode = TJActivity.JavaClass.RESULT_CANCELED) And Assigned(FOnCancel) then FOnCancel(Self);
   end
Else
   if Assigned(FOnError) then FOnError(Self);
end;
{$ENDIF}

Procedure Register;
Begin
RegisterComponents('Imperium Delphi', [TISPhotoGallery]);
End;

Initialization
RegisterFMXClasses([TISPhotoGallery]);

end.
